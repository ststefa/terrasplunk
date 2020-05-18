#!/usr/bin/env python3

# Python 3 server example, https://pythonbasics.org/webserver/

import jsonpath
from http.server import BaseHTTPRequestHandler, HTTPServer

import argparse
import copy
import inspect
import json
import logging
import os
import requests
import socket
import sys
import time
import traceback
import base64
import re
import urllib.parse

import build_state

listen_ip = "0.0.0.0"
listen_port = 8080
user = 'to_be_replaced_as_arg'
password = 'to_be_replaced_as_arg'
health_score_watermark = { 'low' : 100, 'high' : 76, 'critical' : 50 }
coding = 'utf-8'

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
        description='Serve terraform state over http',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--debug', action='store_true',
                        help='Turn on debug output')
    parser.add_argument('--listen', nargs='?', default=listen_ip,
                        help='Listen on specified IP')
    parser.add_argument('--port', nargs='?', type=int, default=listen_port,
                        help='Listen on specified TCP port')
    parser.add_argument('--user', nargs=1, default=user, required=True,
                        help='Splunk REST user')
    parser.add_argument('--password', nargs=1, default=password, required=True,
                        help='Password for Splunk REST user')
    parser.add_argument('--low_watermark', nargs='?', type=int, default=health_score_watermark['low'],
                        help='Low watermark from 0-100 below which the check result is considered not ok')
    parser.add_argument('--high_watermark', nargs='?', type=int, default=health_score_watermark['high'],
                        help='High watermark from 0-100 below which the check result is considered not ok')
    parser.add_argument('--critical_watermark', nargs='?', type=int, default=health_score_watermark['critical'],
                        help='Critical watermark from 0-100 below which the check result is considered not ok')
    return parser


class StateCache():
    """
    A container which caches the terraform data for a short period of time so
    that it does not need to be rebuilt with every HTTP GET request.
    Mainly a measure against DoS.
    """
    @method_trace
    def __init__(self):
        self._state = {}
        self._last_update = 0

    @method_trace
    def _is_valid(self):
        # invalidate cache after several seconds
        is_valid = (round(time.time()) - self._last_update) < 15
        return is_valid

    @method_trace
    def _update(self, new_state):
        self._state = new_state
        self._last_update = round(time.time())

    @method_trace
    def issue(self):
        return self._last_update

    @method_trace
    def get(self):
        if not self._is_valid():
            self._update(build_state.get_state())
        return self._state


class TerraformServer(BaseHTTPRequestHandler):
    _state_cache = StateCache()

    type_table = {
        "cm": "clmaster",
        "dp": "deployer",
        "ds": "dpserver",
        "es": "siem",
        "lm": "license",
        "mt": "deployer",
        "sh": "search",
        # hf and si are treated specially
    }
    stage_table = {
        "d0": "dev",
        "g0": "global",
        "h0": "historic",
        "p0": "prod",
        "t0": "test",
        "w0": "pg",
    }
    role_table = {
        "ao": ["all-in-one"],
        "bd": ["builder"],
        "cm": ["clustermaster", "monitoring-console"],
        "dp": ["deployer"],
        "ds": ["deployment-server"],
        "es": ["entp-searchhead"],
        "hf": ["heavyforwarder"],
        "it": ["itsi-searchhead"],
        "ix": ["indexer"],
        "lm": ["licensemaster"],
        "mc": ["monitoring-console"],
        "mt": ["deployer", "deployment-server"],
        "pr": ["syslog", "heavyforwarder"],
        "sh": ["searchhead"],
        "si": ["single-searchhead"],
        "sy": ["syslog"],
    }
    hardware_table = { # yapf:disable
        "medium.1":  {'ram':1,   'vcpu':1},
        "medium.2":  {'ram':2,   'vcpu':1},
        "medium.4":  {'ram':4,   'vcpu':1},
        "medium.8":  {'ram':8,   'vcpu':1},
        "large.1":   {'ram':2,   'vcpu':2},
        "large.2":   {'ram':4,   'vcpu':2},
        "large.4":   {'ram':8,   'vcpu':2},
        "large.8":   {'ram':16,  'vcpu':2},
        "xlarge.1":  {'ram':4,   'vcpu':4},
        "xlarge.2":  {'ram':8,   'vcpu':4},
        "xlarge.4":  {'ram':16,  'vcpu':4},
        "xlarge.8":  {'ram':32,  'vcpu':4},
        "2xlarge.1": {'ram':8,   'vcpu':8},
        "2xlarge.2": {'ram':16,  'vcpu':8},
        "2xlarge.4": {'ram':32,  'vcpu':8},
        "2xlarge.8": {'ram':64,  'vcpu':8},
        "4xlarge.1": {'ram':16,  'vcpu':16},
        "4xlarge.2": {'ram':32,  'vcpu':16},
        "4xlarge.4": {'ram':64,  'vcpu':16},
        "4xlarge.8": {'ram':128, 'vcpu':16},
        "8xlarge.1": {'ram':32,  'vcpu':32},
        "8xlarge.2": {'ram':64,  'vcpu':32},
        "8xlarge.4": {'ram':128, 'vcpu':32},
        "8xlarge.8": {'ram':256, 'vcpu':32},
    }

    @method_trace
    def hostname_to_link(self, hostname, tenant, stage):
        domain = "splunk.sbb.ch"
        ecs_type = hostname[5:7]
        ecs_stage = hostname[3:5]
        ecs_number = hostname[7:]

        if tenant == "tsch_rz_p_001":
            if ecs_type == "hf":
                return f'<a href="https://{ecs_type}{ecs_number}-{TerraformServer.stage_table[ecs_stage]}.{domain}">{hostname}</a>'
            if ecs_type == "si":
                if stage == "p0" and ecs_number == "000":
                    # Exception for uat searchhead due to discarded u0 stage
                    return f'<a href="https://search-uat.{domain}">{hostname}</a>'
                else:
                    return f'<a href="https://{ecs_type}{ecs_number}-{TerraformServer.stage_table[ecs_stage]}.{domain}">{hostname}</a>'
            if ecs_type in TerraformServer.type_table.keys():
                if ecs_type == "si":
                    return f'<a href="https://{TerraformServer.type_table[ecs_type]}.{domain}">{hostname}</a>'
                else:
                    return f'<a href="https://{TerraformServer.type_table[ecs_type]}-{TerraformServer.stage_table[ecs_stage]}.{domain}">{hostname}</a>'
        else:
            if ecs_type == "hf" or ecs_type in TerraformServer.type_table.keys(): # yapf:disable
                data = TerraformServer._state_cache.get()[tenant][stage]

                # find host in json data
                this_host = None
                compute_instances = jsonpath.jsonpath(data, "$..resources[?(@.type=='opentelekomcloud_compute_instance_v2')]") # yapf: disable
                for instance in compute_instances:
                    log.debug(f'instance:{instance}')
                    if instance['instances'][0]['attributes']['name'] == hostname: # yapf:disable
                        this_host = instance
                        break
                if this_host is not None:
                    return f'<a href="https://{instance["instances"][0]["attributes"]["access_ip_v4"]}:8000">{hostname}</a>'
        # if nothing of the above did apply then return just the simple hostname without any HTML
        return hostname



    @method_trace
    def do_GET(self):
        try:
            self.send_response(200)
            log.debug(f'self.path:{self.path}')
            if self.path == '/tfstate':
                self.send_header("Content-type", "application/json")
                self.end_headers()
                self.do_tfstate()
            elif self.path.startswith('/monitor/health_score'):
                self.send_header("Content-type", "text/html")
                self.end_headers()
                severity = 'low'
                stage = None
                if "?" in self.path:
                    parsed = urllib.parse.parse_qs(self.path.split('?')[1])
                    if 'severity' in parsed:
                        severity = parsed['severity'][0]
                    if 'stage' in parsed:
                        stage = parsed['stage'][0]
                self.do_monitor(severity, stage)
            elif self.path == '/topology':
                self.send_header("Content-type", "text/html")
                self.end_headers()
                self.do_topology()
            elif self.path.startswith('/investigate'):
                self.send_header("Content-type", "text/html")
                self.end_headers()
                self.do_investigate(self.path.split('/investigate/')[1])
            else:
                self.send_header("Content-type", "text/html")
                self.end_headers()
                self.wfile.write(bytes(
                    "<!DOCTYPE html><html><body>Cannot handle this. Humans please use <a href='/topology'>/topology</a>, machines use <a href='/tfstate'>/tfstate</a> and monitors use <a href='/monitor/health_score'>/monitor/health_score</a></body></html>", coding)) #yapf: disable
        except requests.exceptions.HTTPError as http_err:
            self.send_error(http_err.response.status_code,
                            f'{http_err.__class__.__name__} occurred',
                            f'{traceback.format_exc()}')
            log.exception(http_err)
        except Exception as err:
            self.send_error(500, f'Python {err.__class__.__name__} exception',
                            f'Unexpected error: {traceback.format_exc()}')
            log.exception(err)

    @method_trace
    def do_tfstate(self):
        data=TerraformServer._state_cache.get()
        self.wfile.write(bytes(json.dumps(data), coding))

    @method_trace
    def do_monitor(self, severity='low', stage=None):
        splunk_app = 'itsi'
        splunk_auth = requests.auth.HTTPBasicAuth(user, password)
        stage_filter = 'title!=splh0* AND title!=splw0*' if stage==None else f'title=spl{stage}*'
        splunk_search = f"|inputlookup itsi_entities| search {stage_filter} " \
                        f"AND title!=spl*0sy* | fields title |tschcheckserverhealth " \
                        f"| eval health_weight=case(health=\"black\", 7, health=\"green\", 0, health=\"yellow\", 3, " \
                        f"health=\"red\", 5)|eval _time=now() | stats sum(health_weight) as total | eval health_score=100-total"
        splunk_search_params = {'output_mode': 'json', 'search': f'{splunk_search}'}
        splunkREST_search = f'/servicesNS/{user}/{splunk_app}/search/jobs/export'
        splunkURL = f'https://search.splunk.sbb.ch:8089{splunkREST_search}'

        resp = requests.get(splunkURL, auth=(splunk_auth), params=splunk_search_params)
        resp.raise_for_status()
        log.info(f'HTTP {resp.status_code} for URL: {resp.url}')

        data_json = resp.json()
        log.debug(f'HTTP output (JSON): {data_json}')
        result_health_score_str = data_json['result']['health_score']

        #Interpret if Splunk is healthy, providing service, based on result_health_score_str value
        try:
            result_health_score = float(result_health_score_str)
        except ValueError:
            result_health_score = -1.0  #Splunk ITSI health_score is always between 0 - 100 or 'N/A', with -1 we report that service was in maintenance ('N/A')
            interpreted_splunk_health = 'SBB maintenance'
        else:
            if result_health_score < health_score_watermark[severity]:
                interpreted_splunk_health = 'SBB NoOK'
            else:
                interpreted_splunk_health = 'SBB OK'
        log.info(f'HTTP output: result {{ health_score = {result_health_score_str}, ...}}, watermark = {health_score_watermark[severity]}; therefore: {interpreted_splunk_health}')

        #HTML Header
        self.wfile.write(bytes('<!DOCTYPE html>', coding))
        self.wfile.write(bytes('<html>', coding))
        self.wfile.write(bytes('<head><title>Splunk Monitor</title></head>', coding))

        #HTML Body
        self.wfile.write(bytes(f'<body>', coding))
        self.wfile.write(bytes('<h1>Input to Splunk</h1>', coding))
        search_url = f'https://search.splunk.sbb.ch/app/search/search?q={urllib.parse.quote_plus(splunk_search)}'
        self.wfile.write(bytes(f'<p>Run this <a href="{search_url}">search</a> directly in Splunk</p>', coding))
        self.wfile.write(bytes('<h1>Output from Splunk</h1>', coding))
        self.wfile.write(bytes(f'<p><pre>{json.dumps(data_json, indent=4)}</pre></p>', coding))
        self.wfile.write(bytes('<h1>Interpretation of this output</h1>', coding))
        self.wfile.write(bytes(f'<p>Stage {stage} health_score (after converted to float) = {result_health_score}, {severity}_watermark = {health_score_watermark[severity]} ; therefore ...</p>', coding))
        self.wfile.write(bytes(f'<p><b>{interpreted_splunk_health}</b></p>', coding))
        self.wfile.write(bytes('<h1>Splunk System Health</h1>', coding))
        db_link = f'https://search.splunk.sbb.ch/en-GB/app/itsi/serverhealth?form.stage='
        if stage==None:
            db_param = f'title!=splh0* AND title!=splw0* AND title=spl*'
        else:
            db_param = f'title=spl{stage}*'
        # encode URL to get rid of '=', but leave '!' and '*'
        self.wfile.write(bytes(f'<p>Go to <a href="{db_link}{urllib.parse.quote(db_param, safe="*!")}">system health dashboard</a></p>', coding))
        self.wfile.write(bytes('</body>', coding))

        #HTML End
        self.wfile.write(bytes('</html>', coding))

    @method_trace
    def do_investigate(self, server):
        splunk_auth = requests.auth.HTTPBasicAuth(user, password)
        splunkREST_endpoint = f'/servicesNS/{user}/itsi/search/jobs/export'
        splunk_sh = 'search.splunk.sbb.ch'
        splunk_search = f'|makeresults | eval server="{server}" | tschcheckserverhealthdetail'
        splunk_search_params = {'output_mode': 'json', 'search': f'{splunk_search}'}
        splunkURL = f'https://{splunk_sh}:8089{splunkREST_endpoint}'

        url='error'
        data_json='error'
        error_string = ''
        try:
            resp = requests.get(splunkURL, auth=(splunk_auth), params=splunk_search_params, timeout=5)
            resp.raise_for_status()
            log.info(f'HTTP {resp.status_code} for URL: {resp.url}')

            result1 = json.loads(resp.content)['result']['header'][2:]    # string from JSON, skip b'
            result2 = base64.b64decode(result1)                           # bytes
            result3 = result2.decode()                                    # string with inner JSON
            data_json = json.loads(result3)
            log.debug(f'HTTP output (JSON): {data_json}')
            url=resp.url
        except requests.exceptions.HTTPError as http_err:
            log.error(f'Error trying to communicate to {server}: {http_err}')
            error_string=str(http_err)
        except ValueError as err:
            log.error(f'Error trying to communicate to {server}')
            error_string=str(err)
        except Exception as err:
            log.error(f'Error trying to communicate to {server}: {err}')
            error_string=str(err)

        #HTML Header
        self.wfile.write(bytes('<!DOCTYPE html>', coding))
        self.wfile.write(bytes('<html>', coding))
        self.wfile.write(bytes('<head><title>Splunk Investigator</title></head>', coding))

        #HTML Body
        self.wfile.write(bytes(f'<body>', coding))
        self.wfile.write(bytes('<h1>Input to Splunk</h1>', coding))
        self.wfile.write(bytes(f'<p>REST call: <a href="{url}">{url}</a></p>', coding))
        self.wfile.write(bytes('<h1>Output from Splunk</h1>', coding))
        if data_json == 'error':
            self.wfile.write(bytes(f'<p><pre>{error_string}</pre></p>', coding))
        else:
            self.wfile.write(bytes(f'<p><pre>{json.dumps(data_json, indent=4)}</pre></p>', coding))
        self.wfile.write(bytes('</body>', coding))

        #HTML End
        self.wfile.write(bytes('</html>', coding))

    @method_trace
    def do_topology(self):
        self.wfile.write(bytes("<!DOCTYPE html>", coding))
        self.wfile.write(bytes("<html>", coding))

        self.wfile.write(bytes("<head>", coding))
        self.wfile.write(bytes("<title>Splunk Overview</title>", coding))
        self.wfile.write(bytes("\
            <style>\
                body       {font-family: verdana;}\
                h1         {color: green;}\
                table      {border-collapse: collapse; font-size: small;}\
                tr, th, td {text-align: left; vertical-align: top; border: 1px solid; padding: 2px; padding-left: 10px;; padding-right: 10px;}\
                tr         {text-align: left; vertical-align: top; border: 1px solid;}\
                footer     {padding: 10px; color: lightgrey; font-size: small;}\
            </style>"                     , coding))
        self.wfile.write(bytes("</head>", coding))

        self.do_topology_body()

        self.wfile.write(bytes("</html>", coding))


    @method_trace
    def do_topology_body(self):
        self.wfile.write(bytes("<body>", coding))

        self.wfile.write(
            bytes("<h1>Splunk environment overview</h1>", coding))
        for tenant in sorted(TerraformServer._state_cache.get().keys()):
            self.wfile.write(bytes(f'<h2>Tenant {tenant}</h2>', coding))

            self.do_topology_tenant(tenant)

        self.wfile.write(
            bytes(f'<footer>Created with &hearts; on {socket.gethostname()} showing live terraform data as of {time.asctime(time.localtime(round(TerraformServer._state_cache.issue())))}</footer>', coding))

        self.wfile.write(bytes("</body>", coding))

    @method_trace
    def do_topology_tenant(self, tenant):
        data = TerraformServer._state_cache.get()[tenant]

        stages = sorted([key for key in data.keys()])
        stages.remove('shared')

        self.wfile.write(bytes("<table>", coding))

        self.wfile.write(bytes("<tr>", coding))
        for stage in stages:
            self.wfile.write(
                bytes(f'<th width=200>{TerraformServer.stage_table[stage]}</th>', coding))
        self.wfile.write(bytes("</tr>", coding))

        self.wfile.write(bytes("<tr>", coding))
        for stage in stages:
            self.wfile.write(bytes("<td>", coding))
            self.do_topology_stage(tenant, stage)
            self.wfile.write(bytes("</td>", coding))
        self.wfile.write(bytes("</tr>", coding))

        self.wfile.write(bytes("</table>", coding))

    @method_trace
    def do_topology_stage(self, tenant, stage):
        data = TerraformServer._state_cache.get()[tenant][stage]

        self.wfile.write(bytes("<table>", coding))

        try:
            capacity = {'ram': 0, 'vcpu': 0, 'ssd': 0, 'sata': 0}

            blockstorage_query = "$..resources[?(@.type=='opentelekomcloud_blockstorage_volume_v2')]" # yapf: disable
            blockstorages = jsonpath.jsonpath(data, blockstorage_query)
            if blockstorages:
                for disk in blockstorages:
                    d_type=disk['instances'][0]['attributes']['volume_type']
                    if d_type == 'SATA':
                        capacity['sata'] += disk['instances'][0]['attributes']['size']
                    elif d_type == 'SSD':
                        capacity['ssd'] += disk['instances'][0]['attributes']['size']
                    else:
                        log.warn(f'Unknown disk type {d_type}')

            instance_query = "$..resources[?(@.type=='opentelekomcloud_compute_instance_v2')]"
            all_compute_instances = jsonpath.jsonpath(data, instance_query)
            has_instances = False
            if all_compute_instances:
                has_instances = True
                # create temp dict just for sorting
                # yapf:disable
                instance_dict = {}
                for instance in all_compute_instances:
                    i_name = instance['instances'][0]['attributes']['name']
                    i_ip = instance['instances'][0]['attributes']['access_ip_v4']
                    i_id = instance['instances'][0]['attributes']['id']
                    i_az = instance['instances'][0]['attributes']['availability_zone']
                    i_flavor = instance['instances'][0]['attributes']['flavor_id']
                    instance_dict[i_name] = {}
                    instance_dict[i_name]['ip'] = i_ip
                    instance_dict[i_name]['id'] = i_id
                    instance_dict[i_name]['az'] = i_az
                    instance_dict[i_name]['flavor'] = i_flavor
                    capacity['ram'] += TerraformServer.hardware_table[i_flavor[3:]]['ram']
                    capacity['vcpu'] += TerraformServer.hardware_table[i_flavor[3:]]['vcpu']
                for i_name in sorted(instance_dict.keys()):
                    i_type = i_name[5:7]
                    i_ip = instance_dict[i_name]["ip"]
                    i_az = instance_dict[i_name]["az"]
                    i_vcpu = TerraformServer.hardware_table[instance_dict[i_name]["flavor"][3:]]["vcpu"]
                    i_ram = TerraformServer.hardware_table[instance_dict[i_name]["flavor"][3:]]["ram"]
                    i_id = instance_dict[i_name]["id"]
                    self.wfile.write(bytes("<tr><td>", coding))
                    self.wfile.write(bytes(f'<b>{self.hostname_to_link(i_name, tenant, stage)}</b><br>', coding))
                    self.wfile.write(bytes(f'ip: {i_ip}<br>', coding))
                    self.wfile.write(bytes(f'az: {i_az}<br>', coding))
                    self.wfile.write(bytes(f'fl: {i_ram} GB | {i_vcpu} vCPU<br>', coding))
                    self.wfile.write(bytes(f'rl: {", ".join(TerraformServer.role_table[i_type])}<br>', coding))
                    self.wfile.write(bytes(f'id: {i_id}<br>', coding))
                    self.wfile.write(bytes('</td></tr>', coding))
        except Exception:
            log.warn(f'Creating stage failed with {traceback.format_exc()}')
            self.wfile.write(bytes(f'Creating stage failed with {traceback.format_exc()}', "utf-8"))

        if has_instances:
            self.wfile.write(bytes("<tr><td>", coding))
            self.wfile.write(bytes(f'<b>Total capacity:</b><br>', coding))
            self.wfile.write(bytes(f'vcpu: {capacity["vcpu"]}, ', coding))
            self.wfile.write(bytes(f'ram:  {capacity["ram"]}, ', coding))
            self.wfile.write(bytes(f'sata: {capacity["sata"]}, ', coding))
            self.wfile.write(bytes(f'ssd:  {capacity["ssd"]}', coding))
            self.wfile.write(bytes('</td></tr>', coding))

        self.wfile.write(bytes("</table>", coding))


if __name__ == "__main__":
    init_logging()

    parser = init_parser()
    args = parser.parse_args()
    if args.debug:
        log.setLevel(logging.DEBUG)
    if args.port:
        listen_port = args.port
    if args.listen:
        listen_ip = args.listen
    if args.user:
        user = args.user[0]
    if args.password:
        password = args.password[0]
    if args.low_watermark:
        health_score_watermark['low'] = args.low_watermark
    if args.high_watermark:
        health_score_watermark['high'] = args.high_watermark
    if args.critical_watermark:
        health_score_watermark['critical'] = args.critical_watermark

    log.debug(f'sys.argv: {sys.argv}')
    log.debug(f'args: {args}')

    web_server = HTTPServer((listen_ip, listen_port), TerraformServer)
    log.info(f'Server listening on {listen_ip}:{listen_port}')

    try:
        ret_code = 1
        web_server.serve_forever()
    except KeyboardInterrupt:
        ret_code = 0
    finally:
        web_server.server_close()
        log.info("Server stopped.")
        sys.exit(ret_code)
