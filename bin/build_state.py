#!/usr/bin/env python3

import os
import sys
import argparse
import json

import pathlib

import logging

# assign terraform workspace names to otc tenant names
workspace_tenant_map = {
    'default': {
        'tenant_name': 'tsch_rz_t_001',
        'tfstate_path': 'terraform.tfstate'
    },
    'production': {
        'tenant_name': 'tsch_rz_p_001',
        'tfstate_path': 'terraform.tfstate.d/production/terraform.tfstate'
    }
}

# assign real stage names to terraform dir names
stage_map = {'production': 'prod',
             'qa': 'qa',
             'test': 'test',
             'development': 'dev',
             'spielwiese': 'spielwiese'}

log = logging.getLogger(__name__)
# set to DEBUG for early-stage debugging
log.setLevel(logging.INFO)


class TfstateError(Exception):
    pass


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
    # Prevent exception logging while emitting
    logging.raiseExceptions = False


def init_parser(base_path):
    parser = argparse.ArgumentParser(
        description='Create combined output of all the splunk infrastructure that terraform created. The result will be a json formatted dictionary consisting of all tenants and all stages.',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Turn on console debug output')
    parser.add_argument('--root_dir', default=base_path, nargs='?',
                        help='The root path of the splunk terraform project')
    parser.add_argument('-p', '--pretty', action='store_true',
                        help='Prettyprint output')
    return parser


def main():
    init_logging()

    # set our own main path (i.e. the parent path of the dir containing $0)
    base_path = os.path.normpath(
        os.path.join(os.path.dirname(os.path.realpath(__file__)), '..'))

    parser = init_parser(base_path)
    args = parser.parse_args()
    if args.debug:
        log.setLevel(logging.DEBUG)

    log.debug('sys.argv: %s' % sys.argv)
    log.debug('args: %s' % args)

    if args.root_dir:
        base_path = args.root_dir
    log.debug('base_path: %s' % base_path)

    result = {}

    for workspace in workspace_tenant_map.keys():
        tenant = {}
        result[workspace_tenant_map[workspace]['tenant_name']] = tenant
        for stage_name in stage_map.keys():
            stage_path = base_path + '/stages/' + stage_map[stage_name]
            log.debug('stage_path: %s' % stage_path)
            if not pathlib.Path(stage_path).exists():
                raise TfstateError(
                    'ERROR: Cannot find a directory for stage %s (%s), terraform structure incomplete' % (
                    stage_name, stage_path))

            tfstate_filename = stage_path + '/' + \
                               workspace_tenant_map[workspace][
                                   'tfstate_path']
            log.debug('tfstate_filename: %s' % tfstate_filename)
            file = pathlib.Path(tfstate_filename)
            if file.exists():
                with file.open('r') as f:
                    tfstate = json.load(f)
                    f.close()
                tenant[stage_name] = tfstate
            else:
                log.debug("No state for stage %s, workspace %s" % (
                    stage_name, workspace))
                tenant[stage_name] = {}
                continue

    log.info(json.dumps(result, indent=2 if args.pretty else None))


if __name__ == '__main__':
    try:
        main()
    except TfstateError as e:
        log.error(e)
        sys.exit(1)
