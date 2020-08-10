#!/usr/bin/env python3

import argparse
import boto3
import datetime
import decimal
import json
import logging
import os
import random
import socket
import string
import sys

from boto3.dynamodb.conditions import Key, Attr

log = logging.getLogger(__name__)
# set to DEBUG for early-stage debugging, default INFO
log.setLevel(logging.INFO)


class LockStateError(Exception):
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


def init_parser():
    parser = argparse.ArgumentParser(
        description=
        'Lock terraform state by creating an entry for a specific stage in AWS DynamoDB',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('--debug',
                        action='store_true',
                        help='turn on debug output')

    parser.add_argument(
        'tenant',
        help=
        'show instances of this tenant (default derived from current directory if possible)'
    )
    parser.add_argument(
        'stage',
        help=
        'show instances of this stage (default derived from current directory if possible)'
    )
    return parser


def lock_state(tenant, stage):
    db_key = 'sbb-splunkterraform-prod/'
    if tenant.lower() == "tsch_rz_p_001":
        db_key += "env:/production/"
    db_key = f'{db_key}{stage}.tfstate'

    log.debug(f'db_key:{db_key}')

    session = boto3.Session(profile_name='sbb-splunk')
    dynamodb = session.resource('dynamodb', region_name='eu-central-1')

    table = dynamodb.Table('splunkterraform')  # pylint: disable=no-member

    # terraform lock entry looks like this:
    # {
    #    "LockID": "sbb-splunkterraform-prod/w0.tfstate",
    #    "Info": "{\"ID\":\"<UUID>\",\"Operation\":\"OperationTypeApply\",\"Info\":\"\",\"Who\":\"<SBBuser>@splg0bd000.novalocal\",\"Version\":\"<terraform version>\",\"Created\":\"<lockCreationDate>\",\"Path\":\"sbb-splunkterraform-<tenant>/<stage>.tfstate\"}"
    # },

    # every state entry has an associated <key>-md5 entry which is created when
    # the state is imported into S3. If there is no "-md5" entry then there is
    # no state by that key. That's a reliable and maintenance-free way to
    # determine whether the specified tenant/stage exists.
    md5_entry = db_key + '-md5'
    response = table.get_item(Key={
        'LockID': md5_entry,
    })
    if not 'Item' in response.keys():
        raise LockStateError(
            f'Cannot find entry for {db_key} in DynamoDB. Tenant/Stage does not exist.')

    response = table.get_item(Key={
        'LockID': db_key,
    })
    if 'Item' in response.keys():
        raise LockStateError(
            f'Lock already present:\n{json.dumps(response["Item"], indent=2)}')

    chars = string.hexdigits.lower()
    id = ''.join(random.choice(chars) for x in range(8)) + '-' +\
        ''.join(random.choice(chars) for x in range(4)) + '-' +\
        ''.join(random.choice(chars) for x in range(4)) + '-' +\
        ''.join(random.choice(chars) for x in range(4)) + '-' +\
        ''.join(random.choice(chars) for x in range(12))
    log.debug(f'id:{id}')

    now = datetime.datetime.now()
    date = now.strftime('%Y-%m-%dT%H:%M:%S.%fZ')
    log.debug(f'date:{date}')

    who = f'{os.getlogin()}@{socket.gethostname()}'
    log.debug(f'who:{who}')

    table.put_item(
        Item={
            'LockID':
            f'{db_key}',
            'Info':
            f'{{\"ID\":\"{id}\",\"Operation\":\"SafetyLock\",\"Info\":\"Intentionally locked, do NOT use -lock=false. Ask engineering instead.\",\"Who\":\"{who}\",\"Version\":\"\",\"Created\":\"{date}\",\"Path\":\"{db_key}\"}}',
        })
    log.info(f'Locked stage {stage}, tenant {tenant}')


if __name__ == "__main__":
    init_logging()
    parser = init_parser()
    args = parser.parse_args()

    if args.debug:
        log.setLevel(logging.DEBUG)

    log.debug(f'sys.argv: {sys.argv}')
    log.debug(f'args: {args}')

    try:
        lock_state(args.tenant, args.stage)
    except LockStateError as e:
        log.error(e)
        sys.exit(1)
    except Exception as e:
        log.exception(e)
        sys.exit(1)
