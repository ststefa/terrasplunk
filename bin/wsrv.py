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

hostName = "0.0.0.0"
serverPort = 8080

log = logging.getLogger(__name__)
# set to DEBUG for early-stage debugging
log.setLevel(logging.INFO)

try:
    base_path = os.path.normpath(
        os.path.join(os.path.dirname(os.path.realpath(__file__)), '..'))
    log.debug(f'base_path: {base_path}')
except:
    raise

sys.path.append(os.path.realpath(__file__))


def method_trace(fn):
    from functools import wraps

    @wraps(fn)
    def wrapper(*my_args, **my_kwargs):
        log.debug(f'>>> {fn.__name__}({inspect.getargspec(fn)} ; {my_args} ; {my_kwargs})')
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
    parser.add_argument('--listen', nargs='?', default=hostName,
                        help='Listen on specified IP')
    parser.add_argument('--port', nargs='?', default=serverPort,
                        type=int, help='Listen on specified TCP port')
    return parser


@method_trace
def start_server():
    webServer = HTTPServer((hostName, serverPort), TerraformServer)
    print(f'Server started http://{hostName}:{serverPort}')
    return webServer


class StateCache():
    @method_trace
    def __init__(self):
        self._state = {}
        self._last_update = 0

    @method_trace
    def valid(self):
        is_valid = (round(time.time()) - self._last_update) < 15
        return is_valid

    @method_trace
    def update(self, new_state):
        self._state = new_state
        self._last_update = round(time.time())

    @method_trace
    def issue(self):
        return self._last_update

    @method_trace
    def get(self):
        return copy.deepcopy(self._state)


class TerraformServer(BaseHTTPRequestHandler):
    _state_cache = StateCache()

    @method_trace
    def hostname_to_link(self, hostname, tenant):
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
        }
        stage_table = {
            "g0": "global",
            "p0": "prod",
            "t0": "test",
            "w0": "pg",
        }

        if ecs_stage in stage_table.keys():
            if ecs_type == "hf":
                if tenant=="tsch_rz_p_001":
                    return f'<a href="https://{ecs_type}{ecs_number}-{stage_table[ecs_stage]}.{domain}">{hostname}</a>'
                else:
                    return f'<a href="https://ip:8000">{hostname}</a>'
            if ecs_type in type_table.keys():
                if tenant=="tsch_rz_p_001":
                    return f'<a href="https://{type_table[ecs_type]}-{stage_table[ecs_stage]}.{domain}">{hostname}</a>'
                else:
                    return f'<a href="https://ip:8000">{hostname}</a>'
            else:
                return hostname
        else:
            return hostname



    @method_trace
    def do_GET(self):
        try:
            if not TerraformServer._state_cache.valid():
                TerraformServer._state_cache.update(
                    build_state.get_state(build_state.base_path))
            self.send_response(200)
            log.debug(f'self.path:{self.path}')
            if self.path == '/tfstate':
                self.send_header("Content-type", "application/json")
                self.end_headers()
                self.do_tfstate(TerraformServer._state_cache.get())
            elif self.path == '/topology':
                self.send_header("Content-type", "text/html")
                self.end_headers()
                self.do_topology(TerraformServer._state_cache.get())
            elif self.path == '/monitor/health_score':
                self.send_header("Content-type", "text/html")
                self.end_headers()
                self.do_monitor()
            else:
                self.send_header("Content-type", "text/html")
                self.end_headers()
                self.wfile.write(bytes(
                    "<!DOCTYPE html><html><body>Cannot handle this. Humans please use <a href='/topology'>/topology</a>, machines use <a href='/tfstate'>/tfstate</a> and monitors use <a href='/monitor/health_score'>/monitor/health_score</a></body></html>", "utf-8"))
        except Exception as err:
            self.send_error(500, f'Python {err.__class__.__name__} exception', f'Unexpected error: {traceback.format_exc()}')
            raise

    @method_trace
    def do_tfstate(self, data):
        self.wfile.write(bytes(json.dumps(data), "utf-8"))

    @method_trace
    def do_topology(self, data):
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
            </style>", "utf-8"))
        self.wfile.write(bytes("</head>", "utf-8"))

        self.do_body(data)

        self.wfile.write(bytes("</html>", "utf-8"))

    @method_trace
    def do_monitor(self):
        coding = 'utf-8'
        user = 'functional_user_monitor'
        password = 'functional_user_monitor'
        splunk_app = 'itsi'
        splunk_auth = requests.auth.HTTPBasicAuth(user, password)
        splunk_search = 'monitorSplunkHealth'
        splunk_search_params = {'output_mode': 'json', 'search': f'savedsearch {splunk_search}'}
        splunkREST_savedSearches = f'/servicesNS/{user}/{splunk_app}/search/jobs/export'
        splunkURL = f'https://search.splunk.sbb.ch:8089{splunkREST_savedSearches}'

        #TODO: This should probably rather re-raise the exception like in do_GET(). Logging output is not visible to the HTTP client
        try:
            resp = requests.get(splunkURL, auth=splunk_auth, params=splunk_search_params)
            resp.raise_for_status()
        except requests.exceptions.HTTPError as http_err:
            log.error(f'HTTP error occurred: {http_err}')
        except Exception as err:
            log.error(f'Genneric error occured: {err}')
        log.info(f'HTTP {resp.status_code} for URL: {resp.url}')

        try:
            data_json = resp.json()
            log.debug(f'HTTP output (JSON): {data_json}')
        except ValueError:
            log.error(f'ValueError decoding Splunk response "{resp.text}"')

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
    def do_body(self, data):
        self.wfile.write(bytes("<body>", "utf-8"))

        self.wfile.write(
            bytes("<h1>Splunk environment overview</h1>", "utf-8"))
        for tenant in sorted(data.keys()):
            self.wfile.write(bytes(f'<h2>Tenant {tenant}</h2>', "utf-8"))

            self.do_tenant(data[tenant], tenant)

        self.wfile.write(
            bytes(f'<footer>Created with &hearts; on {socket.gethostname()} showing live terraform data as of {time.asctime(time.localtime(round(TerraformServer._state_cache.issue())))}</footer>', "utf-8"))

        self.wfile.write(bytes("</body>", "utf-8"))

    @method_trace
    def do_tenant(self, data, tenant):
        del data['shared']
        self.wfile.write(bytes("<table>", "utf-8"))

        self.wfile.write(bytes("<tr>", "utf-8"))
        for stage in sorted(data.keys()):
            self.wfile.write(
                bytes(f'<th width=180>Stage {stage}</th>', "utf-8"))
        self.wfile.write(bytes("</tr>", "utf-8"))

        self.wfile.write(bytes("<tr>", "utf-8"))
        for stage in sorted(data.keys()):
            self.wfile.write(bytes("<td>", "utf-8"))
            self.do_stage(data[stage], tenant)
            self.wfile.write(bytes("</td>", "utf-8"))
        self.wfile.write(bytes("</tr>", "utf-8"))

        self.wfile.write(bytes("</table>", "utf-8"))

    @method_trace
    def do_stage(self, data, tenant):
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
                    self.wfile.write(bytes(f'<b>{self.hostname_to_link(i_name, tenant)}</b><br>', "utf-8"))
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
        serverPort = args.port
    if args.listen:
        hostName = args.listen

    log.debug(f'sys.argv: {sys.argv}')
    log.debug(f'args: {args}')

    web_server = HTTPServer((hostName, serverPort), TerraformServer)
    log.info(f'Server listening on {hostName}:{serverPort}')

    try:
        web_server.serve_forever()
    except KeyboardInterrupt:
        pass

    web_server.server_close()
    log.info("Server stopped.")
