#!/usr/bin/env python3

# Python 3 server example, https://pythonbasics.org/webserver/

import jsonpath
from http.server import BaseHTTPRequestHandler, HTTPServer
import time

import os
import copy
import sys
import argparse
import json
import logging
import socket

import build_state

hostName = "0.0.0.0"
serverPort = 8080

log = logging.getLogger(__name__)
# set to DEBUG for early-stage debugging
log.setLevel(logging.INFO)

try:
    base_path = os.path.normpath(
        os.path.join(os.path.dirname(os.path.realpath(__file__)), '..'))
    log.debug('base_path: %s' % base_path)
except:
    raise

sys.path.append(os.path.realpath(__file__))


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
        description='Serve terraform state over http',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--debug', action='store_true',
                        help='Turn on debug output')
    parser.add_argument('--port', nargs='?', default=serverPort,
                        type=int, help='Listen on specified TCP port')
    return parser


def start_server():
    webServer = HTTPServer((hostName, serverPort), TerraformServer)
    print("Server started http://%s:%s" % (hostName, serverPort))
    return webServer


class StateCache():
    def __init__(self):
        self._state = {}
        self._last_update = 0

    def valid(self):
        is_valid = (round(time.time()) - self._last_update) < 15
        return is_valid

    def update(self, new_state):
        self._state = new_state
        self._last_update = round(time.time())

    def issue(self):
        return self._last_update

    def get(self):
        return copy.deepcopy(self._state)


class TerraformServer(BaseHTTPRequestHandler):
    _state_cache = StateCache()

    def do_GET(self):
        if not TerraformServer._state_cache.valid():
            TerraformServer._state_cache.update(
                build_state.get_state(build_state.base_path))
        self.send_response(200)
        log.debug('self.path:%s' % self.path)
        if self.path == '/tfstate':
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.do_raw(TerraformServer._state_cache.get())
        elif self.path == '/topology':
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.do_html(TerraformServer._state_cache.get())
        else:
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write(bytes(
                "<!DOCTYPE html><html><body>Cannot handle this. Humans please use <a href='/topology'>/topology</a>, machines use <a href='/tfstate'>/tfstate</a></body></html>", "utf-8"))

    def do_raw(self, data):
        self.wfile.write(bytes(json.dumps(data), "utf-8"))

    def do_html(self, data):
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

    def do_body(self, data):
        self.wfile.write(bytes("<body>", "utf-8"))

        self.wfile.write(
            bytes("<h1>Splunk environment overview</h1>", "utf-8"))
        for tenant in sorted(data.keys()):
            self.wfile.write(bytes("<h2>Tenant %s</h2>" % tenant, "utf-8"))

            self.do_tenant(data[tenant])

        self.wfile.write(
            bytes("<footer>Created with &hearts; on %s showing live terraform data as of  %s</footer>" %
                  (socket.gethostname(), time.asctime(time.localtime(round(TerraformServer._state_cache.issue())))), "utf-8"))

        self.wfile.write(bytes("</body>", "utf-8"))

    def do_tenant(self, data):
        del data['shared']
        self.wfile.write(bytes("<table>", "utf-8"))

        self.wfile.write(bytes("<tr>", "utf-8"))
        for stage in sorted(data.keys()):
            self.wfile.write(
                bytes("<th width=180>Stage %s</th>" % stage, "utf-8"))
        self.wfile.write(bytes("</tr>", "utf-8"))

        self.wfile.write(bytes("<tr>", "utf-8"))
        for stage in sorted(data.keys()):
            self.wfile.write(bytes("<td>", "utf-8"))
            self.do_stage(data[stage])
            self.wfile.write(bytes("</td>", "utf-8"))
        self.wfile.write(bytes("</tr>", "utf-8"))

        self.wfile.write(bytes("</table>", "utf-8"))

    def do_stage(self, data):
        self.wfile.write(bytes("<table>", "utf-8"))

        instance_query = "$..resources[?(@.type=='opentelekomcloud_compute_instance_v2')]"
        all_compute_instances = jsonpath.jsonpath(data, instance_query)
        if all_compute_instances:
            for instance in all_compute_instances:
                self.wfile.write(bytes("<tr><td>", "utf-8"))
                self.wfile.write(bytes("<b>%s</b></br>" %
                                       instance['instances'][0]['attributes']['name'], "utf-8"))
                self.wfile.write(bytes("%s</br>" %
                                       instance['instances'][0]['attributes']['access_ip_v4'], "utf-8"))
                self.wfile.write(bytes("%s</br>" %
                                       instance['instances'][0]['attributes']['availability_zone'], "utf-8"))
                self.wfile.write(bytes("%s</br>" %
                                       instance['instances'][0]['attributes']['flavor_id'], "utf-8"))
                self.wfile.write(bytes("</td></tr>", "utf-8"))

        self.wfile.write(bytes("</table>", "utf-8"))


if __name__ == "__main__":
    init_logging()

    parser = init_parser()
    args = parser.parse_args()
    if args.debug:
        log.setLevel(logging.DEBUG)
    if args.port:
        serverPort = args.port

    log.debug('sys.argv: %s' % sys.argv)
    log.debug('args: %s' % args)

    web_server = HTTPServer((hostName, serverPort), TerraformServer)
    log.info("Server listening on %s:%s" % (hostName, serverPort))

    try:
        web_server.serve_forever()
    except KeyboardInterrupt:
        pass

    web_server.server_close()
    log.info("Server stopped.")
