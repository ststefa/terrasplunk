#!/usr/bin/env python3
"""
This collects all available terraform state and writes it to stdout as a json
structure. Further doc on the structure of the output can be found in the
top-level README
"""

import os
import re
import sys
import argparse
import json
import time

# noinspection PyCompatibility
import pathlib

import logging

log = logging.getLogger(__name__)
# set to DEBUG for early-stage debugging
log.setLevel(logging.INFO)

# assign terraform workspace names to otc tenant names
workspace_tenant_map = {  # TODO: remove if terraform.workspace==tenantname
    'default': {
        'tenant_name': 'tsch_rz_t_001',
        'tfstate_path': 'terraform.tfstate'
    },
    'production': {
        'tenant_name': 'tsch_rz_p_001',
        'tfstate_path': 'terraform.tfstate.d/production/terraform.tfstate'
    }
}


class TfstateError(Exception):
    pass


# set our own main path (i.e. the parent path of the dir containing $0)
# base_path=""
try:
    base_path = os.path.normpath(
        os.path.join(os.path.dirname(os.path.realpath(__file__)), '..'))
    log.debug(f'base_path: {base_path}')
except:
    raise TfstateError('Cannot determine base path')


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
        description=
        'Create combined output of all the splunk infrastructure that terraform created. The result will be a json formatted dictionary consisting of all tenants and all stages.',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--debug',
                        action='store_true',
                        help='Turn on console debug output')
    parser.add_argument(
        '--root_dir',
        default=base_path,
        nargs='?',
        help=
        'The root path of the splunk terraform project containing the state files'
    )
    parser.add_argument('-p',
                        '--pretty',
                        action='store_true',
                        help='Prettyprint output')
    return parser


def get_state(base_path):
    stage_path = os.path.join(base_path, 'stages')
    shared_path = os.path.join(base_path, 'shared')
    result = {}
    # Any stages/* dir which matches this regex is considered a stage dir
    reg_stagename = re.compile("..")

    # Iterate over tenants
    for workspace in workspace_tenant_map.keys():
        tenant = {}
        result[workspace_tenant_map[workspace]['tenant_name']] = tenant

        # Add shared to tenant
        tfstate_filename = os.path.join(
            shared_path, workspace_tenant_map[workspace]['tfstate_path'])
        log.debug(f'shared tfstate_filename: {tfstate_filename}')
        file = pathlib.Path(tfstate_filename)
        if file.exists():
            with file.open('r') as f:
                tfstate = json.load(f)
                f.close()
            tenant["shared"] = tfstate
        else:
            log.warning(f'No shared state for tenant {workspace_tenant_map[workspace]["tenant_name"]} (workspace {workspace})')

        # Add stages to tenant
        # dynamically get stages based on existing dirs
        stages = os.listdir(stage_path)
        for stage in stages:
            log.debug(f'stage: {stage}')
            stagedir = os.path.join(base_path, stage)
            if os.path.isdir(stagedir):
                stages.remove(stage)
            if not reg_stagename.fullmatch(stage):
                stages.remove(stage)
        log.debug(f'stages: {stages}')

        # iterate over stage dirs, adding their tfstate
        for stage_name in stages:
            this_stage_path = os.path.join(stage_path, stage_name)
            log.debug(f'this_stage_path: {this_stage_path}')

            tfstate_filename = os.path.join(
                this_stage_path,
                workspace_tenant_map[workspace]['tfstate_path'])
            log.debug(f'tfstate_filename: {tfstate_filename}')
            file = pathlib.Path(tfstate_filename)
            if file.exists():
                with file.open('r') as f:
                    tfstate = json.load(f)
                    f.close()
                tenant[stage_name] = tfstate
            else:
                log.debug(f'No state for stage {stage_name}, workspace {workspace}')
                tenant[stage_name] = {}
                continue
    return result


def main(base_path):
    init_logging()

    parser = init_parser(base_path)
    args = parser.parse_args()
    if args.debug:
        log.setLevel(logging.DEBUG)

    log.debug(f'sys.argv: {sys.argv}')
    log.debug(f'args: {args}')

    if args.root_dir:
        base_path = args.root_dir
    log.debug(f'base_path: {base_path}')

    # The final result to ppoulate
    result = get_state(base_path)

    log.info(json.dumps(result, indent=2 if args.pretty else None))


if __name__ == '__main__':
    try:
        main(base_path)
    except TfstateError as e:
        log.error(e)
        sys.exit(1)
