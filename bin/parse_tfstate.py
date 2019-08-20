#!/usr/bin/env python3

# This is just test code

import os
import sys
import json

base_path = os.path.normpath(
    os.path.join(os.path.dirname(os.path.realpath(__file__)), '..', 'lib'))
sys.path.append(base_path)
import jsonpath

with open('terraform.tfstate', 'r') as f:
    tfstate = json.load(f)

result = {'roles': {'indexers': [], 'searchheads': []}, 'hosts': [], 'configs': []}

for instance in jsonpath.jsonpath(tfstate, "$.resources[?(@.type=='opentelekomcloud_compute_instance_v2')]"):
    result['roles']['indexers'].append(instance['instances'][0]['attributes']['name'])
    result['hosts'].append(instance['instances'][0]['attributes']['name'])
    config = {}
    config['hostname'] = instance['instances'][0]['attributes']['name']
    config['ipv4'] = instance['instances'][0]['attributes']['access_ip_v4']
    #config['az'] = instance['instances'][0]['attributes']['availability_zone']
    #config['id'] = instance['instances'][0]['attributes']['id']
    #print("$.resources[?(@.type=='openstack_compute_volume_attach_v2')].instances[0].attributes[?(@.instance_id=='%s')]" % config['id'])

    attach_dict = {}
    for attach in jsonpath.jsonpath(tfstate, "$.resources[?(@.type=='opentelekomcloud_compute_volume_attach_v2')]"):
        #print(attach['instances'][0]['attributes']['device']+','+attach['instances'][0]['attributes']['instance_id'])
        if attach['instances'][0]['attributes']['instance_id'] == instance['instances'][0]['attributes']['id']:
            attach_dict[attach['name']]=attach['instances'][0]['attributes']['device']
    config['pvs']=attach_dict

    result['configs'].append(config)

print(json.dumps(result, indent=None))
