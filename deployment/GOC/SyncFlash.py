#! /usr/bin/python
#-------------------------------------------------------------------------------
# Name:        SyncFlash.py
# Purpose:
#
# Author:      jack.zhang
#
# Created:     04/06/2014
# Copyright:   (c) jack.zhang 2014
# Licence:     <your licence>
#-------------------------------------------------------------------------------
import os,sys,subprocess,logging
import time,getopt,ConfigParser
info = 0
error = 2

def Log(logs,logfile,log_message,level):
    log_file =logs+'/'+logfile
    logger=logging.getLogger()
    handler=logging.FileHandler(log_file)
    formatter = logging.Formatter("[%(asctime)s] %(levelname)s: %(message)s")
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    logger.setLevel(logging.NOTSET)
    if level == 2:
        logger.error(log_message)
        print log_message
    else:
        logger.info(log_message)
        print log_message
    logger.removeHandler(handler)


def ConfigFile(file,label):
    try:
        config = ConfigParser.ConfigParser()
        config.read(file)
        try:
            CasinoDir = config.get(label, 'CasinoDir')
            LobbyDir = config.get(label, 'LobbyDir')
            #ConfDir = config.get(label, 'ConfDir')
            S3urlPath = config.get(label, 'S3urlPath')
            LogPath = config.get(label, 'LogPath')
            #return CasinoDir, LobbyDir, ConfDir, S3urlPath, LogPath
            return CasinoDir, LobbyDir, S3urlPath, LogPath        
        except ConfigParser.NoSectionError:
            print "%s name does not exist" % label
            sys.exit(1)
    except IOError:
        print "Error reading configuration file"
        sys.exit(1)

def sync2s3(name, s3cmd, s3path, s3url, logpath):
    path = s3path
    if (name == 'lobby'):
        s3url = s3url + '/lobby'
    elif (name == 'casino'):
        s3url = s3url + '/casino'
    # elif (name == 'conf'):
    #     s3url = s3url + '/conf'
    # print "s3url = %s" % s3url
    if os.path.exists(path) == False:
        stderr =  "The [%s] directory does not exist" % path
        return stderr,error
    shell_commd = '%s %s/ %s/' % (s3cmd,path,s3url)
    stdout = os.popen(shell_commd).read()
    status = os.popen('echo $?').read().strip()
    if status != "0":
        stderr = '[%s]  synchronize failure'% s3url
        return stderr,error
    else:
        return '%s%s synchronize success' % (stdout, s3url), info

if __name__ == '__main__':
    # global variable
    Config_File = '/home/qa/deployment/script/conf/SyncFlash.ini'
    s3cmd = "s3cmd sync --delete-removed -P --add-header=Cache-Control:no-cache --recursive"
    date = time.strftime("%Y%m%d", time.localtime())
    logfile = 'syncflash%s.log'% date

    # Script parameters
    opts, args = getopt.getopt(sys.argv[1:], "-d:-h:n:")
    project = args[0]
    param = args[1]
    # main
    #CasinoDir, LobbyDir, ConfDir, S3urlPath, LogPath = ConfigFile(Config_File, project)
    CasinoDir, LobbyDir, S3urlPath, LogPath = ConfigFile(Config_File, project)
    if (param == 'lobby'or param =='all'):
        #print "%s %s %s" % (s3cmd, ConfDir, S3urlPath)
        print "%s %s" % (s3cmd, S3urlPath)
        message, level = sync2s3('lobby', s3cmd, LobbyDir, S3urlPath, LogPath)
        Log(LogPath, logfile, message, level)
    if (param == 'casino' or param == 'all'):
        #print "%s %s %s" % (s3cmd, ConfDir, S3urlPath)
        print "%s %s" % (s3cmd, S3urlPath)
        message, level = sync2s3('casino', s3cmd, CasinoDir, S3urlPath, LogPath)
        Log(LogPath, logfile, message, level)
    # if (param == 'conf' or param == 'all'):
    #     print "%s %s %s" % (s3cmd, ConfDir, S3urlPath)
    #     message, level = sync2s3('conf', s3cmd, ConfDir, S3urlPath, LogPath)
    #     Log(LogPath, logfile, message, level)
