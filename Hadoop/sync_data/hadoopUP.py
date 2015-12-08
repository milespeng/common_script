#!/usr/bin/python
# coding=utf-8
# __author__ = 'miles.peng'


import os
import subprocess
import pdb


targtDir="/home/hadoop/bak0623/bak/goc_oplog/log_playerdailylogin/"
def command(param):
    try:
        shell = subprocess.Popen(param,shell=True,close_fds=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
        stdout,stderr = shell.communicate()
    except:
        logger.error("command excute failed!!!")
    return stdout,stderr

def getFilePath(targtDir):
    paths=[]
    for f in os.listdir(targtDir):
        targetDir = os.path.join(targtDir,  f)
        print "targetDir is ..%s" % targetDir
        if os.path.isdir(targetDir):
        # os.remove(targetFile)
            paths.append(targetDir)
    return paths

def runCommand(paths):
    for f in paths:
        cmd="hadoop fs -put %s /userdata/playerdailylogin/" % f
        print cmd
        print "\n"
        stdout,stderr = command(cmd)

if __name__ == '__main__':
   # pdb.set_trace()
    paths=getFilePath(targtDir)
    runCommand(paths)

