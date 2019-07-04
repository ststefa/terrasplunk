#!/usr/bin/env python3

import json
import jsonpath

with open('terraform.tfstate', 'r') as f:
    tfstate = json.load(f)

result = {'roles': {'indexer': [], 'searchhead': []}, 'hosts': [], 'config': []}

for instance in jsonpath.jsonpath(tfstate, "$.resources[?(@.type=='openstack_compute_instance_v2')]"):
    result['roles']['indexer'].append(instance['instances'][0]['attributes']['name'])
    result['hosts'].append(instance['instances'][0]['attributes']['name'])
    config = {}
    config['hostname'] = instance['instances'][0]['attributes']['name']
    config['ipv4'] = instance['instances'][0]['attributes']['access_ip_v4']
    config['az'] = instance['instances'][0]['attributes']['availability_zone']
    config['id'] = instance['instances'][0]['attributes']['id']
    print("$.resources[?(@.type=='openstack_compute_volume_attach_v2')].instances[0].attributes[?(@.instance_id=='%s')]" % config['id'])
    for attach in jsonpath.jsonpath(tfstate, "$.resources[?(@.type=='openstack_compute_volume_attach_v2')]"):
        print(attach['instances'][0]['attributes']['device'])
        config['attach'] = attach['instances'][0]['attributes']['device']

    result['config'].append(config)

print(json.dumps(result, indent="  "))
