#! /usr/bin/python

__author__ = 'william.wu'

import ConfigParser,re
import os, subprocess, logging, datetime

confName = "/home/aspect/tools/conf/autoCreateImage.ini"
awsCli = "/usr/local/bin/aws"
#confName = "autoCreateImage.ini"
awsVars = {}
now = datetime.datetime.now()
newDate = now.strftime('%Y%m%d')
delta = now + datetime.timedelta(days=-14)
oldDate = delta.strftime('%Y%m%d')

def init_log():
    # set basic config when printing file;
    try:
        logging.basicConfig(level=logging.INFO,
                            format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
                            datefmt='%a, %d %b %Y %H:%M:%S',
                            filename='/home/aspect/tools/logs/autoCreateImage.log',
                            filemode='a')
        # set basic config when printing console;
        console = logging.StreamHandler()
        console.setLevel(logging.INFO)
        formatter = logging.Formatter('%(name)-12s: %(levelname)-8s %(message)s')
        console.setFormatter(formatter)
        logging.getLogger('').addHandler(console)
    except IOError,e:
        print "Can not open log file", e
        exit(1)


def exec_cmd(command):
    try:
        shell = subprocess.Popen(command, shell=True, close_fds=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = shell.communicate()
    except Exception,e:
        msg = "Can not command line:",e
        logging.error(msg)
        exit(1)
    if stdout != '':
        logging.info(stdout)
        return stdout
    else:
        logging.error(stderr)
        return stderr


def create_image():
    for key in awsVars.iterkeys():
        args = awsVars[key].split(',')
        cmd = "%s --profile %s ec2 create-image --instance-id %s --name \"%s-%s\" --no-reboot" % (awsCli, args[0], args[1], args[2], newDate)
        logging.info(cmd)
        exec_cmd(cmd)


def delete_image():
    for key in awsVars.iterkeys():
        args = awsVars[key].split(',')
        cmd = "%s ec2 --profile %s describe-images --filters \"Name=name,Values=%s-%s\"" % (awsCli, args[0], args[2], oldDate)
        logging.info(cmd)
        result = exec_cmd(cmd)
        #Get ami-id based on AMI name
        match = re.search(ur"(ami-\S+)", result)
        #delete AMI if matching image id
        if match:
            cmd = "%s ec2 --profile %s deregister-image --image-id %s" % (awsCli, args[0], match.group(0))
            logging.info(cmd)
            exec_cmd(cmd)
        else:
            logging.error("doesn't match any ami id")


def read_conf():
    # read configuration and return dictionary
    conf = ConfigParser.ConfigParser()
    conf.read(confName)
    sections = conf.sections()
    for secs in sections:
        instanceID = conf.get(secs, "instanceID")
        imageName = conf.get(secs, "name")
        profile = conf.get(secs, "profile")
        awsVars[secs] = "%s,%s,%s" % (profile, instanceID, imageName)


if __name__ == "__main__":
    init_log()
    logging.info("-------------------Staring-------------------------")
    read_conf()
    create_image()
    delete_image()
    logging.info("-------------------Ending-------------------------")



