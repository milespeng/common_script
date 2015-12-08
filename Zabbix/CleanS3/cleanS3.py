#! /usr/bin/python

__author__ = 'william.wu'

import ConfigParser,re
import os, subprocess, logging, datetime

confName = "/home/aspect/tools/conf/cleanS3.ini"
#confName = "cleanS3.ini"
awsCli = "/usr/local/bin/aws"
AWSVars = {}

def init_log():
    # set basic config when printing file;
    try:
        logging.basicConfig(level=logging.INFO,
                            format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
                            datefmt='%a, %d %b %Y %H:%M:%S',
                            filename='/home/aspect/tools/logs/cleanS3.log',
                            filemode='a')
        # set basic config when printing console;
        console = logging.StreamHandler()
        console.setLevel(logging.INFO)
        formatter = logging.Formatter('%(name)-12s: %(levelname)-8s %(message)s')
        console.setFormatter(formatter)
        logging.getLogger('').addHandler(console)
    except IOError,e:
        print "Can't open log file", e
        exit(1)

def read_conf():
    # read configuration and return dictionary
    global AWSVars
    global confName
    conf = ConfigParser.ConfigParser()
    conf.read(confName)
    sections = conf.sections()
    for secs in sections:
        bucket = conf.get(secs, "bucket")
        prefix = conf.get(secs, "prefix")
        profile = conf.get(secs, "profile")
        retention = conf.get(secs,"retention")
        AWSVars[secs] = "%s,%s,%s,%s" % (bucket, prefix, profile, retention)

def exec_cmd(command):
    try:
        shell = subprocess.Popen(command, shell=True, close_fds=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = shell.communicate()
    except Exception,e:
        msg = "Can't execute command line:",e
        logging.error(msg)
        exit(1)
    if stdout != '':
        logging.info(stdout)
        return stdout
    else:
        logging.error(stderr)
        return stderr


def get_pattern(period):
    now = datetime.datetime.now()
    #Get previous months
    pattern = ''
    for index in range(int(period)):
        days = index * 30
        delta = now + datetime.timedelta(days=-days)
        #newdate = delta.strftime('%Y-%m-%d')
        newdate = delta.strftime('%Y-%m')
        #print newdate
        if ( index+1 == int(period)):
            pattern = pattern + newdate
        else:
            pattern = pattern + newdate + "|"
    #Filter prefix when list files in S3
    pattern = pattern + '|PRE'
    return pattern


def remove_files():
    global AWSVars
    global pattern
    now = datetime.datetime.now()
    #get retention period from dict
    for key in AWSVars.iterkeys():
        msg = "Parameters:%s" % (AWSVars[key])
        logging.info(msg)
        args = AWSVars[key].split(',')
        pattern = get_pattern(args[3])
        msg = "Pattern:%s" % (pattern)
        logging.info(msg)
        cmd = "%s s3 ls s3://%s/%s/" % (awsCli, args[0], args[1])
        logging.info(cmd)
        f = os.popen(cmd,'r')
        for eachLine in f.readlines():
            match = re.search(pattern, eachLine)
            if match:
                continue
            else:
                eachList = re.split( '\s+', eachLine)
                logging.info(eachList)
                cmd = '%s s3 rm s3://%s/%s/%s' % (awsCli, args[0], args[1], eachList[3])
                logging.info(cmd)
                exec_cmd(cmd)
        f.close()


if __name__ == "__main__":
    init_log()
    logging.info("-------------------Staring-------------------------")
    read_conf()
    remove_files()
    logging.info("-------------------Ending-------------------------")
    test



