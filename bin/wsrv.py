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

import build_state

listen_ip = "0.0.0.0"
listen_port = 8080
user = 'to_be_replaced_as_arg'
password = 'to_be_replaced_as_arg'

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
    parser.add_argument('--port', nargs='?', default=listen_port,
                        type=int, help='Listen on specified TCP port')
    parser.add_argument('--user', nargs='?', default=user,
                        help='Splunk REST user')
    parser.add_argument('--password', nargs='?', default=password,
                        help='Password for Splunk REST user')
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
            self._update(build_state.get_state(build_state.base_path))
        return self._state


class TerraformServer(BaseHTTPRequestHandler):
    _state_cache = StateCache()

    @method_trace
    def hostname_to_link(self, hostname, tenant, stage):
        domain="splunk.sbb.ch"
        ecs_type=hostname[5:7]
        ecs_stage=hostname[3:5]
        ecs_number=hostname[7:]
        type_table = {
            "cm": "clmaster",
            "dp": "deployer",
            "ds": "dpserver",
            "es": "siem",
            "lm": "license",
            "mt": "deployer",
            "sh": "search",
            "si": "search-uat", #ugly hack because there is not u0 stage anymore
        }
        stage_table = {
            "g0": "global",
            "p0": "prod",
            "t0": "test",
            "w0": "pg",
        }

        if tenant=="tsch_rz_p_001":
            if ecs_type == "hf":
                return f'<a href="https://{ecs_type}{ecs_number}-{stage_table[ecs_stage]}.{domain}">{hostname}</a>'
            if ecs_type in type_table.keys():
                if ecs_type == "si":
                    return f'<a href="https://{type_table[ecs_type]}.{domain}">{hostname}</a>'
                else:
                    return f'<a href="https://{type_table[ecs_type]}-{stage_table[ecs_stage]}.{domain}">{hostname}</a>'
        else:
            if ecs_type == "hf" or ecs_type in type_table.keys():
                data = TerraformServer._state_cache.get()[tenant][stage]

                # find host in json data
                this_host = None
                compute_instances = jsonpath.jsonpath(data, "$..resources[?(@.type=='opentelekomcloud_compute_instance_v2')]") # yapf: disable
                for instance in compute_instances:
                    log.debug(f'instance:{instance}')
                    if instance['instances'][0]['attributes']['name'] == hostname:
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
            elif self.path == '/monitor/health_score':
                self.send_header("Content-type", "text/html")
                self.end_headers()
                self.do_monitor()
            elif self.path == '/topology':
                self.send_header("Content-type", "text/html")
                self.end_headers()
                self.do_topology()
            else:
                self.send_header("Content-type", "text/html")
                self.end_headers()
                self.wfile.write(bytes(
                    "<!DOCTYPE html><html><body>Cannot handle this. Humans please use <a href='/topology'>/topology</a>, machines use <a href='/tfstate'>/tfstate</a> and monitors use <a href='/monitor/health_score'>/monitor/health_score</a></body></html>", "utf-8")) #yapf: disable
        except requests.exceptions.HTTPError as http_err:
            self.send_error(http_err.response.status_code,
                            f'{http_err.__class__.__name__} occured',
                            f'{traceback.format_exc()}')
            log.exception(http_err)
        except Exception as err:
            self.send_error(500, f'Python {err.__class__.__name__} exception',
                            f'Unexpected error: {traceback.format_exc()}')
            log.exception(err)

    @method_trace
    def do_tfstate(self):
        data=TerraformServer._state_cache.get()
        self.wfile.write(bytes(json.dumps(data), "utf-8"))

    @method_trace
    def do_monitor(self):
        coding = 'utf-8'
        splunk_app = 'itsi'
        splunk_auth = requests.auth.HTTPBasicAuth(user, password)
        splunk_search = f"|inputlookup itsi_entities| search title!=splh0* AND title!=splw0* " \
                         "AND title!=spl*0sy* AND title=spl*| fields title |tschcheckserverhealth " \
                         "| eval health_weight=case(health=\"black\", 5, health=\"green\", 0, health=\"yellow\", 3, " \
                         "health=\"red\", 5)|eval _time=now() | stats sum(health_weight) as total | eval health_score=100-total"
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
            if result_health_score < 100:
                interpreted_splunk_health = 'SBB NoOK'
            else:
                interpreted_splunk_health = 'SBB OK'
        log.info(f'HTTP output: result {{ health_score = {result_health_score_str}, ...}}; therefore: {interpreted_splunk_health}')

        #HTML Header
        self.wfile.write(bytes('<!DOCTYPE html>', coding))
        self.wfile.write(bytes('<html>', coding))
        self.wfile.write(bytes('<head><title>Splunk Monitor</title></head>', coding))

        #HTML Body
        self.wfile.write(bytes(f'<body>', coding))
        self.wfile.write(bytes('<h1>Input to Splunk</h1>', coding))
        self.wfile.write(bytes(f'<p>REST call: <a href="{resp.url}">{resp.url}</a></p>', coding))
        self.wfile.write(bytes('<h1>Output from Splunk</h1>', coding))
        self.wfile.write(bytes(f'<p><pre>{json.dumps(data_json, indent=4)}</pre></p>', coding))
        self.wfile.write(bytes('<h1>Interpretation of this output</h1>', coding))
        self.wfile.write(bytes(f'<p>health_score (after converted to float) = {result_health_score} ; therefore ...</p>', coding))
        self.wfile.write(bytes(f'<p><b>{interpreted_splunk_health}</b></p>', coding))
        self.wfile.write(bytes('</body>', coding))

        #HTML End
        self.wfile.write(bytes('</html>', coding))

    @method_trace
    def do_topology(self):
        self.wfile.write(bytes("<!DOCTYPE html>", "utf-8"))
        self.wfile.write(bytes("<html>", "utf-8"))

        self.wfile.write(bytes("<head>", "utf-8"))
        self.wfile.write(bytes("<title>Splunk Overview</title>", "utf-8"))
        self.wfile.write(bytes("\
            <style>\
                body       {font-family: verdana;}\
                h1         {color: green;}\
                table      {border-collapse: collapse; font-size: small;}\
                tr, th, td {text-align: left; vertical-align: top; border: 1px solid; padding: 2px; padding-left: 30px;; padding-right: 30px;}\
                tr         {text-align: left; vertical-align: top; border: 1px solid;}\
                footer     {padding: 10px; color: lightgrey; font-size: small;}\
            </style>"                                                                                                                                                   , "utf-8"))
        self.wfile.write(bytes("</head>", "utf-8"))

        self.do_topology_body()

        self.wfile.write(bytes("</html>", "utf-8"))


    @method_trace
    def do_topology_body(self):
        self.wfile.write(bytes("<body>", "utf-8"))

        self.wfile.write(
            bytes("<h1>Splunk environment overview</h1>", "utf-8"))
        for tenant in sorted(TerraformServer._state_cache.get().keys()):
            self.wfile.write(bytes(f'<h2>Tenant {tenant}</h2>', "utf-8"))

            self.do_topology_tenant(tenant)

        self.wfile.write(
            bytes(f'<footer>Created with &hearts; on {socket.gethostname()} showing live terraform data as of {time.asctime(time.localtime(round(TerraformServer._state_cache.issue())))}</footer>', "utf-8"))

        self.wfile.write(bytes("</body>", "utf-8"))

    @method_trace
    def do_topology_tenant(self, tenant):
        data = TerraformServer._state_cache.get()[tenant]

        stages = sorted([key for key in data.keys()])
        stages.remove('shared')

        self.wfile.write(bytes("<table>", "utf-8"))

        self.wfile.write(bytes("<tr>", "utf-8"))
        for stage in stages:
            self.wfile.write(
                bytes(f'<th width=180>Stage {stage}</th>', "utf-8"))
        self.wfile.write(bytes("</tr>", "utf-8"))

        self.wfile.write(bytes("<tr>", "utf-8"))
        for stage in stages:
            self.wfile.write(bytes("<td>", "utf-8"))
            self.do_topology_stage(tenant, stage)
            self.wfile.write(bytes("</td>", "utf-8"))
        self.wfile.write(bytes("</tr>", "utf-8"))

        self.wfile.write(bytes("</table>", "utf-8"))

    @method_trace
    def do_topology_stage(self, tenant, stage):
        data = TerraformServer._state_cache.get()[tenant][stage]

        self.wfile.write(bytes("<table>", "utf-8"))

        try:
            instance_query = "$..resources[?(@.type=='opentelekomcloud_compute_instance_v2')]"
            all_compute_instances = jsonpath.jsonpath(data, instance_query)
            if all_compute_instances:
                # create temp dict just for sorting
                instance_dict = {}
                for instance in all_compute_instances:
                    i_name = instance['instances'][0]['attributes']['name']
                    instance_dict[i_name] = {}
                    instance_dict[i_name]['ip'] = instance['instances'][0]['attributes']['access_ip_v4']
                    instance_dict[i_name]['az'] = instance['instances'][0]['attributes']['availability_zone']
                    instance_dict[i_name]['flavor'] = instance['instances'][0]['attributes']['flavor_id']
                for i_name in sorted(instance_dict.keys()):
                    self.wfile.write(bytes("<tr><td>", "utf-8"))
                    self.wfile.write(bytes(f'<b>{self.hostname_to_link(i_name, tenant, stage)}</b><br>', "utf-8"))
                    self.wfile.write(bytes(f'{instance_dict[i_name]["ip"]}<br>', "utf-8"))
                    self.wfile.write(bytes(f'{instance_dict[i_name]["az"]}<br>', "utf-8"))
                    self.wfile.write(bytes(f'{instance_dict[i_name]["flavor"]}<br>', "utf-8"))
                    self.wfile.write(bytes('</td></tr>', "utf-8"))
        except Exception as e:
            log.warn(f'Creating stage failed with {e}')

        self.wfile.write(bytes("</table>", "utf-8"))


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
        user = args.user
    if args.password:
        password = args.password

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
