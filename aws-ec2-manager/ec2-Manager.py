#!/usr/bin/python
import logging
import ConfigParser
import subprocess
import sys
import boto.ec2
import pdb
def log_init():
    # set basic config when printing file;
    try:
        logging.basicConfig(level=logging.INFO,
                            format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
                            datefmt='%a, %d %b %Y %H:%M:%S',
                            filename='ec2_manager.log',
                            filemode='a')
        # set basic config when printing console;
        console = logging.StreamHandler()
        console.setLevel(logging.INFO)
        formatter = logging.Formatter('%(name)-12s: %(levelname)-8s %(message)s')
        console.setFormatter(formatter)
        logging.getLogger('').addHandler(console)
        return  True
    except IOError,e:
        print "Can't open log file", e
        exit(1)

def run_cmd(cmd):
    print "Starting run: %s "%cmd
    cmdref = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    out = cmdref.stdout.read()
    print "run cmd  output "+out
    data = cmdref.communicate()
    if cmdref.returncode == 0:
        msg = "Run %s success \n" % cmd
        print(msg)
        return out
    else:
        msg = "[ERROR] Run %s False \n" % cmd
        msg = msg + data[1]
        print msg
        sys.exit(1)

def get_config(sections,configName):
    cf=ConfigParser.ConfigParser()
    cf.read(configName)
    configDataSection=cf.sections()
    returnData={}
    if sections in configDataSection:
        list_section=cf.items(sections)
        list_default=cf.items("default")
        list_all=list_section+list_default
        for _key,_value in list_all:
            returnData[_key]=_value
    else:
        print "[ERROR] %s is not in config files,PLS check it %s" %(sections,configName)
        sys.exit(1)
    return returnData

def get_ec2_info(params):
    aws_access_key_id=params['aws_access_key_id']
    aws_secret_access_key=params['aws_secret_access_key']
    region=params['region']
    filters=eval(params['filters'])
    conn=boto.ec2.connect_to_region(region,aws_access_key_id=aws_access_key_id,aws_secret_access_key=aws_secret_access_key)
    reservations = conn.get_all_instances(filters=filters)
    instances = [i for r in reservations for i in r.instances]
    instance_ids=[]
    for item in instances:
        instance_ids.append(item.id)
    return  instance_ids

'''
    stop instance (list)
    run_stop=conn.stop_instances(instance_ids)
    start instance
    run_start=conn.start_instances(instance_ids)

dir(instances):
['__class__', '__delattr__', '__dict__', '__doc__', '__format__', '__getattribute__', '__hash__', '__init__', '__module__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', '_in_monitoring_element', '_placement', '_previous_state', '_state', '_update', 'add_tag', 'add_tags', 'ami_launch_index', 'architecture', 'block_device_mapping', 'client_token', 'confirm_product', 'connection', 'create_image', 'dns_name', 'ebs_optimized', 'endElement', 'eventsSet', 'get_attribute', 'get_console_output', 'group_name', 'groups', 'hypervisor', 'id', 'image_id', 'instance_profile', 'instance_type', 'interfaces', 'ip_address', 'item', 'kernel', 'key_name', 'launch_time', 'modify_attribute', 'monitor', 'monitored', 'monitoring', 'monitoring_state', 'persistent', 'placement', 'placement_group', 'placement_tenancy', 'platform', 'previous_state', 'previous_state_code', 'private_dns_name', 'private_ip_address', 'product_codes', 'public_dns_name', 'ramdisk', 'reason', 'reboot', 'region', 'remove_tag', 'remove_tags', 'requester_id', 'reset_attribute', 'root_device_name', 'root_device_type', 'sourceDestCheck', 'spot_instance_request_id', 'start', 'startElement', 'state', 'state_code', 'state_reason', 'stop', 'subnet_id', 'tags', 'terminate', 'unmonitor', 'update', 'use_ip', 'virtualization_type', 'vpc_id']
'''

def ec2_start():
    pass

def ec2_stop(instance_list_check):
    pass

def main():
    log_init()
    params=get_config(sys.argv[1],'aws-config.ini')
    instance_list=get_ec2_info(params)
    for i in instance_list:
        msg="%s will be close \n"%i
        logging.info(msg)
    #ec2_stop(instance_list)

if __name__=="__main__":
    main()

