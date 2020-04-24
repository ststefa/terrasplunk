#!/usr/bin/env python3

import jsonpath

import argparse
import boto3
import botocore.exceptions
import inspect
import json
import logging
import sys
import traceback
import re
import pathlib

log = logging.getLogger(__name__)
# set to DEBUG for early-stage debugging, default INFO
log.setLevel(logging.INFO)


def method_trace(fn):
    from functools import wraps

    @wraps(fn)
    def wrapper(*my_args, **my_kwargs):
        log.debug(
            f'>>> {fn.__name__}({inspect.getargspec(fn)} ; {my_args} ; {my_kwargs})'
        )
        out = fn(*my_args, **my_kwargs)
        log.debug(f'<<< {fn.__name__}')
        return out

    return wrapper


@method_trace
def init_logging():
    # write INFO to stdout and anything else to stderr
    # see https://stackoverflow.com/questions/2302315/how-can-info-and-debug-logging-message-be-sent-to-stdout-and-higher-level-messag
    class IsEqualFilter(logging.Filter):
        def __init__(self, level, name=""):
            logging.Filter.__init__(self, name)
            self.level = level

        def filter(self, record):
            # non-zero return means we log this message
            return 1 if record.levelno == self.level else 0

    class IsNotEqualFilter(logging.Filter):
        def __init__(self, level, name=""):
            logging.Filter.__init__(self, name)
            self.level = level

        def filter(self, record):
            # non-zero return means we log this message
            return 1 if record.levelno != self.level else 0

    logging_handler_out = logging.StreamHandler(sys.stdout)
    logging_handler_out.addFilter(IsEqualFilter(logging.INFO))
    log.addHandler(logging_handler_out)
    logging_handler_err = logging.StreamHandler(sys.stderr)
    logging_handler_err.addFilter(IsNotEqualFilter(logging.INFO))
    log.addHandler(logging_handler_err)


@method_trace
def prep_arg_defaults():
    # initialize all dynamic defaults with None
    result = {'tenant': None, 'stage': None}

    cwd = pathlib.Path('.')
    terraform_workspace_file = pathlib.Path(cwd / '.terraform' / 'environment')
    if terraform_workspace_file.exists():
        workspace = terraform_workspace_file.read_text()
        if workspace == "default":
            result['tenant'] = "tsch_rz_t_001"
        elif workspace == "production":
            result['tenant'] = "tsch_rz_p_001"
        result['stage'] = cwd.resolve().name
        # This might be confusing becuase its potentially overriden
        #log.warn( f'Using tenant {result["tenant"]} and stage {result["stage"]} derived from current terraform workspace')

    return result


@method_trace
def init_parser(arg_defaults):
    parser = argparse.ArgumentParser(
        description=
        'Print a list of splunk servers in tenant/stage matching specified criteria. Multiple criteria are logically and-ed. If the current directory is a terraform directory then tenant and stage will be determined automatically. Otherwise they must be specified explicitly. If specified then they override the determined values.',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('--debug',
                        action='store_true',
                        help='turn on debug output')
    parser.add_argument(
        '-v',
        '--verbose',
        action='store_true',
        help=
        'show details as json output. Default is to only report hostnames (one per line)'
    )
    parser.add_argument(
        '-p',
        '--pretty',
        action='store_true',
        help='prettyprint json output, only applies to --verbose')

    parser.add_argument('--az',
                        help='only show instances in availability zone 1 or 2')
    parser.add_argument(
        '--flv', help='only show instances whose flavor matches this regex')
    parser.add_argument(
        '--name', help='only show instances whose name matches this regex')

    parser.add_argument(
        '--format',
        help=
        'use custom format string for output instead of just the hostname. The string will have the following tokens replaced: %%name, %%ip, %%az, %%flv, %%type, %%num, %%tenant, %%stage. Collides with --verbose'
    )

    parser.add_argument('--profile',
                        default='sbb-splunk',
                        help='use a non-default AWS profile for credentials')

    parser.add_argument(
        'tenant',
        nargs='?',
        default=arg_defaults['tenant'],
        help=
        'show instances of this tenant (default derived from current directory if possible)'
    )
    parser.add_argument(
        'stage',
        nargs='?',
        default=arg_defaults['stage'],
        help=
        'show instances of this stage (default derived from current directory if possible)'
    )
    return parser


class ServerlistError(Exception):
    pass


@method_trace
def get_state_from_s3(args):
    s3_key = ""
    try:
        if args.tenant.lower() == "tsch_rz_p_001":
            s3_key += "env:/production/"
        s3_key = f'{s3_key}{args.stage}.tfstate'

        log.debug(f'Fetching {s3_key}from S3')
        session = boto3.Session(profile_name=args.profile)
        s3 = session.client('s3')
        s3_object = s3.get_object(Bucket='sbb-splunkterraform-prod',
                                  Key=s3_key)
        data = json.loads(s3_object['Body'].read())
        return data
    except botocore.exceptions.ClientError:
        raise ServerlistError(
            f'Cannot find any S3 data for key "{s3_key}"') from None


@method_trace
def print_servers(data, args):
    instance_query = "$..resources[?(@.type=='opentelekomcloud_compute_instance_v2')]"
    all_compute_instances = jsonpath.jsonpath(data, instance_query)
    if all_compute_instances:
        instance_dict = {}
        for instance in all_compute_instances:
            instance_name = instance['instances'][0]['attributes']['name']
            instance_dict[instance_name] = {}
            instance_dict[instance_name]['ip'] = instance['instances'][0][
                'attributes']['access_ip_v4']
            instance_dict[instance_name]['az'] = instance['instances'][0][
                'attributes']['availability_zone']
            instance_dict[instance_name]['flavor'] = instance['instances'][0][
                'attributes']['flavor_id']
        if args.name is not None:
            regex = re.compile(args.name, re.IGNORECASE)
            removals = [
                name for name in instance_dict.keys() if not regex.search(name)
            ]
            for name in removals:
                log.debug(f'remove {name}: {instance_dict.pop(name)}')
        if args.az is not None:
            if args.az == "1":
                az = "eu-ch-01"
            elif args.az == "2":
                az = "eu-ch-02"
            else:
                raise ServerlistError(
                    f'Invalid AZ "{args.az}". Use "1" for AZ1/eu-ch-01 or "2" for AZ2/eu-ch-02'
                )
            removals = [
                name for name in instance_dict.keys()
                if not instance_dict[name]['az'] == az
            ]
            for name in removals:
                log.debug(f'remove {name}: {instance_dict.pop(name)}')
        if args.flv is not None:
            regex = re.compile(args.flv, re.IGNORECASE)
            removals = [
                name for name in instance_dict.keys()
                if not regex.search(instance_dict[name]['flavor'])
            ]
            for name in removals:
                log.debug(f'remove {name}: {instance_dict.pop(name)}')

        if args.verbose:
            log.info(
                json.dumps(instance_dict, indent=2 if args.pretty else None))
        else:
            format_string = "%name" if args.format is None else args.format
            for instance_name in sorted(instance_dict.keys()):
                out_line = format_string.replace('%name', instance_name)
                out_line = out_line.replace('%type', instance_name[5:7])
                out_line = out_line.replace('%num', instance_name[7:])
                out_line = out_line.replace('%ip',
                                            instance_dict[instance_name]['ip'])
                out_line = out_line.replace('%az',
                                            instance_dict[instance_name]['az'])
                out_line = out_line.replace(
                    '%flv', instance_dict[instance_name]['flavor'])
                out_line = out_line.replace('%tenant', args.tenant)
                out_line = out_line.replace('%stage', args.stage)
                out_line = out_line.replace('%az',
                                            instance_dict[instance_name]['az'])

                log.info(out_line)


if __name__ == "__main__":
    init_logging()

    arg_defaults = prep_arg_defaults()
    parser = init_parser(arg_defaults)
    args = parser.parse_args()

    if args.debug:
        log.setLevel(logging.DEBUG)

    log.debug(f'sys.argv: {sys.argv}')
    log.debug(f'args: {args}')

    try:
        if args.verbose and args.format is not None:
            raise ServerlistError(
                'Cannot use --verbose togehter with --format')
        if args.pretty and not args.verbose:
            raise ServerlistError(
                'Can only use --pretty togehter with --verbose')
        if args.tenant is None or args.stage is None:
            raise ServerlistError(
                'Not inside a terraform directory. Cannot determine tenant and stage automatically. Please supply tenant and stage explicitly.'
            )

        state = get_state_from_s3(args)
        print_servers(state, args)
    except ServerlistError as e:
        log.error(e)

    sys.exit()
