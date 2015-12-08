#!/usr/bin/python
# coding=utf-8
# __author__ = 'miles.peng'

import datetime
import os
import logging
import pdb
import subprocess
import sys

class ManageDB(object):
    configFile='/home/aspect/tools/conf/ManageDB.ini'
    bakPath='/home/aspect/tools/bak/DB/'
    logFiles='/tmp/DBManage.log'
    expiration=1

    def init_log(self):
        # set basic config when printing file;
        try:
            logging.basicConfig(level=logging.INFO,
                                format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
                                datefmt='%a, %d %b %Y %H:%M:%S',
                                filename=self.logFiles,
                                filemode='a')
            # set basic config when printing console;
            console=logging.StreamHandler()
            console.setLevel(logging.INFO)
            formatter=logging.Formatter('%(name)-12s: %(levelname)-8s %(message)s')
            console.setFormatter(formatter)
            logging.getLogger('').addHandler(console)
        except IOError, e:
            print "Can't open log file", e
            exit(1)


    def backupDB(self, produceName, config):
        dbHost=config.get(produceName, 'dbHost')
        dbUser=config.get(produceName, 'dbUser')
        dbPass=config.get(produceName, 'dbPass')
        dbNameAll=config.get(produceName, 'dbName')
        #pdb.set_trace()
        TargPath=self.bakPath + produceName.lower()
        if isinstance(dbNameAll, str):
            dbName=dbNameAll
            print 'Dumping %s, please wait....' % dbName
            now=datetime.datetime.now().strftime('%Y-%m-%d-%H-%M')
            dumpFileName='%s_%s_%s.sql' % (produceName, dbName, now)
            cmd="/usr/bin/mysqldump -h%s -u%s -p%s %s > %s/%s" % (
                dbHost, dbUser, dbPass, dbName, TargPath, dumpFileName)
            self.runCMD(cmd)
        elif isinstance(dbNameAll, list):
            dbNameList=dbNameAll.split(';')
            for dbName in dbNameList:
                print 'Dumping %s, please wait....' % dbName
                now=datetime.datetime.now().strftime('%Y-%m-%d-%H-%M')
                dumpFileName='%s_%s_%s.sql' % (produceName, dbName, now)
                cmd="/usr/bin/mysqldump -h%s -u%s -p%s %s > %s/%s" % (
                    dbHost, dbUser, dbPass, dbName, TargPath, dumpFileName)
                self.runCMD(cmd)
        return TargPath

        
    def restoreDB(self, produceName, config):
        dbHost=config.get(produceName, 'dbHost')
        dbUser=config.get(produceName, 'dbUser')
        dbPass=config.get(produceName, 'dbPass')

        TargPath=self.bakPath + produceName
        restoreFileHash={}
        print 'Please select sqlfile to restore.'
        for j in range(len(os.listdir(TargPath))):
            print '%s:%s' % (j + 1, os.listdir(TargPath)[j])
            restoreFileHash[j + 1]='%s/%s' % (TargPath, os.listdir(TargPath)[j])
        thisKey=raw_input("")
        restoreFile=restoreFileHash[int(thisKey)]
        dbName=restoreFile.split('_')[1]
        print 'Now begin to restore %s' % restoreFile
        cmd="/usr/bin/mysql -h%s -u%s -p%s %s < %s" % (dbHost, dbUser, dbPass, dbName, restoreFile)
        print "CMD is ..%s" % cmd

    # self.runCMD(cmd)

    def clearBak(self, TargPath):
        import datetime

        fileList=[]
        removeList=[]
        #pdb.set_trace()
        fileList=os.listdir(TargPath)
        for checkfile in fileList:
            filestat=os.stat(TargPath +'/'+checkfile)
            createday=datetime.date.fromtimestamp(filestat.st_ctime)
            today=datetime.date.today()
            if (today - createday).days >= self.expiration:
                removeList.append(TargPath +'/'+ checkfile)
        if len(removeList) > 0:
            for removeFiles in removeList:
                cmd = "rm %s" % removeFiles
                self.runCMD(cmd)


    def sync2S3(self,TargPath,produceName):
        cmd="s3cmd --delete-removed  sync  %s/ s3://aspectgaming-databackup/DB/%s/" % (TargPath,produceName)
        self.runCMD(cmd)



    def runCMD(self, cmd):
        msg="Command:" + cmd
        logging.info(msg + '\n')
        p=subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        while True:
            buff=p.stdout.readline()          
            process_state=p.wait()    
            if buff == '' :
                #logging.info(cmd)
                break
            else:
                if process_state==0:
                    logging.info(buff)
                else:
                    logging.error(buff)
                


    def chooseAct(self):
        print 'What action do you want to do with DB?'
        print '1:dump'
        print '2:restore'
        action={"1": "dump", "2": "restore"}
        actionKey=raw_input("")
        act=action[actionKey.strip()]
        return act


    def getConfig(self):
        import ConfigParser

        config=ConfigParser.ConfigParser()
        config.read(self.configFile)
        #pdb.set_trace()
        # input={}
        # print "PLS choose Targer Production name \n"
        # i=1
        # for a in config.sections():
            # input[i]=a
            # print "%s ..............%s" % (i, a)
            # i=i + 1
        # inputKey=int(raw_input(""))
        # produceName=input[inputKey]
        return config


if __name__ == '__main__':
    dbManage=ManageDB()
    dbManage.init_log()
    argvNum=len(sys.argv)
    act=sys.argv[1].lower()
    produceName=sys.argv[2].lower()
    logging.info("-------------------------Start--------------------------\n")
    #act=dbManage.chooseAct()
    # pdb.set_trace()
    config=dbManage.getConfig()
    if act == "backup":
        msg="It will Backup %s DB ..\n" % produceName
        logging.info(msg)
        TargPath=dbManage.backupDB(produceName, config)
        dbManage.clearBak(TargPath)
        dbManage.sync2S3(TargPath,produceName)
    elif act == "restore":
        msg="It will restore %s DB ..\n" % produceName
        logging.info(msg)
        dbManage.restoreDB(produceName, config)
    else:
        print "Pls Choose Correct Key !! \n"
        logging.info("-------------------------End-----------------------------\n")


