#!/usr/bin/env python3

import jsonpath

import argparse
import boto3
import inspect
import json
import logging
import sys
import traceback
import re

log = logging.getLogger(__name__)
# set to DEBUG for early-stage debugging
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
def init_parser():
    parser = argparse.ArgumentParser(
        description=
        'Print a list of splunk servers amtching certain criteria. If multiple criteria are specified they are logically ANDed.',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--debug',
                        action='store_true',
                        help='Turn on debug output')
    parser.add_argument(
        '-v',
        '--verbose',
        action='store_true',
        help=
        'Show details as json output. Default is to only report hostnames (one per line)'
    )
    parser.add_argument(
        '-p',
        '--pretty',
        action='store_true',
        help='prettyprint json output, only applies to --verbose')
    parser.add_argument('--az',
                        help='Only show instances in availability zone 1 or 2')
    parser.add_argument(
        '--flv', help='Only show instances whose flavor matches this regex')
    parser.add_argument(
        '--id',
        help='Only show instances whose id (aka name) matches this regex')
    parser.add_argument('tenant', help='Show instances of this tenant')
    parser.add_argument('stage', help='Show instances of this stage')
    return parser


class ServerlistError(Exception):
    pass


@method_trace
def get_state_from_s3(tenant, stage):

    key = ""
    if tenant.lower() == "tsch_rz_p_001":
        key += "env:/production/"
    key = f'{key}{stage}.tfstate'

    session = boto3.Session(profile_name='sbb-splunk')
    s3 = session.client('s3')
    s3_object = s3.get_object(Bucket='sbb-splunkterraform-prod', Key=key)
    data = json.loads(s3_object['Body'].read())
    return data


@method_trace
def print_servers(data, args):
    instance_query = "$..resources[?(@.type=='opentelekomcloud_compute_instance_v2')]"
    all_compute_instances = jsonpath.jsonpath(data, instance_query)
    if all_compute_instances:
        instance_dict = {}
        for instance in all_compute_instances:
            i_name = instance['instances'][0]['attributes']['name']
            instance_dict[i_name] = {}
            instance_dict[i_name]['ip'] = instance['instances'][0][
                'attributes']['access_ip_v4']
            instance_dict[i_name]['az'] = instance['instances'][0][
                'attributes']['availability_zone']
            instance_dict[i_name]['flavor'] = instance['instances'][0][
                'attributes']['flavor_id']
        if args.id is not None:
            regex = re.compile(args.id, re.IGNORECASE)
            removals = [
                name for name in instance_dict.keys() if not regex.search(name)
            ]
            for name in removals:
                log.debug(f'remove {instance_dict.pop(name, None)}')
        if args.az is not None:
            if args.az == "1":
                az = "eu-ch-01"
            elif args.az == "2":
                az = "eu-ch-02"
            else:
                raise ServerlistError(
                    'Invalid value, choose "1" for AZ1/eu-ch-01 or "2" for AZ2/eu-ch-02'
                )
            removals = [
                name for name in instance_dict.keys()
                if not instance_dict[name]['az'] == az
            ]
            for name in removals:
                log.debug(f'remove {instance_dict.pop(name, None)}')
        if args.flv is not None:
            regex = re.compile(args.flv, re.IGNORECASE)
            removals = [
                name for name in instance_dict.keys()
                if not regex.search(instance_dict[name]['flavor'])
            ]
            for name in removals:
                log.debug(f'remove {instance_dict.pop(name, None)}')

        if args.verbose:
            log.info(json.dumps(instance_dict))
        else:
            for i_name in sorted(instance_dict.keys()):
                log.info(i_name)


if __name__ == "__main__":
    init_logging()

    parser = init_parser()
    args = parser.parse_args()
    if args.debug:
        log.setLevel(logging.DEBUG)

    log.debug(f'sys.argv: {sys.argv}')
    log.debug(f'args: {args}')

    state = get_state_from_s3(args.tenant, args.stage)
    print_servers(state, args)
    sys.exit()
