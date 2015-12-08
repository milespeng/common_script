#! /usr/bin/python

import os,sys,logging,datetime,time,subprocess,ConfigParser
import shutil

HDFSDir = "/user/hive/warehouse/"
hadoopPath = "/opt/cdh3/hadoop-0.20.2-cdh3u6/bin/hadoop"
hivePath = "/opt/cdh3/hive-0.7.1-cdh3u6/bin/hive"
s3CMDPath = "/usr/bin/s3cmd"

CMD_TestFromHdfs = hadoopPath+" fs -test -d "
CMD_CopyFromHdfs = hadoopPath+" fs -copyToLocal "

conf = "HDFSBackup.ini"
logfile = "HDFSBackup.log"


def command(param):
    try:
        shell = subprocess.Popen(param,shell=True,close_fds=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
        stdout,stderr = shell.communicate()
    except:
        logger.error("command excute failed!!!")
    return stdout,stderr

def getCurrentTime():
    return time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time()))

def callHDFSCMD(hdfslocalpath,dbName,tableName,mydate,type,logger):

    basePath = HDFSDir+dbName+".db/"+tableName
    tmpPath = "/p_date=" + mydate
    path = basePath + tmpPath
    strHDFSCMD = ""
    if type == 1:
        strHDFSCMD = CMD_TestFromHdfs + path
    elif type == 2:
        localDir = hdfslocalpath +dbName + "/"+tableName
        strHDFSCMD = CMD_CopyFromHdfs + path + " "+ localDir + tmpPath +"/"  
    else:
        logger.warn("callHDFSCMD:type error!!!")
    
    print strHDFSCMD
    logger.info(strHDFSCMD)     
    stdout,stderr = command(strHDFSCMD)
    return stdout,stderr 


def callHiveCMD(mydate,dbName,tableName,logger):
    strHiveCMD = "%s -e \"use %s;ALTER TABLE %s DROP PARTITION (p_date='%s');\""%(hivePath,dbName,tableName,mydate)
    print strHiveCMD
    logger.info(strHiveCMD)     
    stdout,stderr = command(strHiveCMD)
    return stdout,stderr

def callS3CMD(hdfslocalpath,dbName,tableName,s3backuppath,s3Fold,logger):
    try:
        localDir = hdfslocalpath +dbName + "/"+tableName
        strS3CMD = "%s sync %s/ %s%s/"%(s3CMDPath,localDir,s3backuppath,s3Fold)
        print strS3CMD
        logger.info(strS3CMD)
        stdout,stderr = command(strS3CMD)
    except:
        logger.error("s3 sync failed!!!")
        info = sys.exc_info()
        logger.error(str(info[0])+":"+str(info[1]))
        sys.exit(1)
    return stdout,stderr

def getConfig(section,logger):
    try:
        config = ConfigParser.ConfigParser()
        config.read(conf)
        dbName = config.get(section, "dbname")
        s3backuppath = config.get(section, "s3backuppath")
        hdfslocalpath = config.get(section, "hdfslocalpath")
        lstTable = []
        options = config.options(section)
        for option in options:
            if option.find("table") != -1:
                lstTable.append(config.get(section, option))
    except IOError:
        print "Read configuration file faild!!!"
        logger.error("Read configuration file faild!!!")
        sys.exit(1) 
    return dbName,s3backuppath,hdfslocalpath,lstTable

def removeFileInFirstDir(targetDir):
    for f in os.listdir(targetDir):
        targetFile = os.path.join(targetDir,  f)
        #print targetFile
        if os.path.isdir(targetFile):
        # os.remove(targetFile)
            shutil.rmtree(targetFile)

if __name__ == '__main__':

    logging.basicConfig(filename = os.path.join(os.getcwd(), logfile), level = logging.INFO, filemode = 'a', format = '%(asctime)s - %(levelname)s: %(message)s')
    logger = logging.getLogger("")
    
    argNum = len(sys.argv)
    if argNum != 4:
        message = "Parameter is :{section|startDate|endDate}"
        print message
        exit(0)

    logger.info("----------------------------------------------------------------------")
    logger.info("---------------------Start time:%s------------------"%getCurrentTime())

    section = sys.argv[1]
    startDate = sys.argv[2]
    endDate = sys.argv[3]
    
    lsStartDate = startDate.split("-")
    lsEndDate = endDate.split("-")
    startDate = datetime.datetime(int(lsStartDate[0]), int(lsStartDate[1]), int(lsStartDate[2]))
    endDate = datetime.datetime(int(lsEndDate[0]), int(lsEndDate[1]), int(lsEndDate[2]))
    logger.info("section:%s,startDate:%s,endDate:%s"%(section,startDate,endDate))
    #print "section:%s,startDate:%s,endDate:%s"%(section,startDate,endDate)
    
    #getConfig
    (dbName,s3backuppath,hdfslocalpath,lstTable)= getConfig(section,logger)
    #print "dbName:%s,s3backuppath:%s,hdfslocalpath:%s,tableDict:%s"%(dbName,s3backuppath,hdfslocalpath,lstTable)
           
    for tableInfo in lstTable:
        (tableName,s3Fold) = tableInfo.split(":")
        myDay = startDate
        logger.info("*****current table is %s******",tableName)
        #basePath = HDFSDir+dbName+".db/"+tableName
        while (myDay<=endDate):
            formatMyDay = myDay.strftime('%Y-%m-%d')

            stdout,stderr = callHDFSCMD(hdfslocalpath,dbName,tableName,str(formatMyDay),1,logger)
            logger.info("TestFromHdfs:output:%s"%stdout)
            if stderr != '':
                logger.warn("TestFromHdfs warn!!!")
                logger.warn(stderr)
                myDay = myDay + datetime.timedelta(1) 
                continue
              
            #copy file from hdfs to local
            stdout,stderr = callHDFSCMD(hdfslocalpath,dbName,tableName,str(formatMyDay),2,logger)
            logger.info("CopyFromHdfs:output:%s"%stdout)
            if stdout != '':
                logger.warn("CopyFromHdfs warn!!!")
                logger.warn(stderr)
                myDay = myDay + datetime.timedelta(1) 
                continue
            myDay = myDay + datetime.timedelta(1)
            """
            #delete data from hive
            stdout,stderr = callHiveCMD(str(formatMyDay),dbName,tableName,logger)
            if stdout != '':
                logger.error("callHiveCMD failed!!!")
                logger.error(stderr)
                myDay = myDay + datetime.timedelta(1) 
                continue            

            myDay = myDay + datetime.timedelta(1)
            
    for tableInfo in lstTable:
            # sync S3
            (tableName,s3Fold) = tableInfo.split(":")
            stdout,stderr = callS3CMD(hdfslocalpath,dbName,tableName,s3backuppath,s3Fold,logger)
            if stderr != '':
                logger.error("callS3CMD failed!!!")
                logger.error(stderr)
                sys.exit(1)
    logger.info("***Finish Syncing S3.***")
    
    #remove file from local directory     
    removeFileInFirstDir(hdfslocalpath)
    #logger.info("***Finish removing file from local directory.***")
    """
    print "endtime:%s"%getCurrentTime()
    logger.info("----------------------------------------------------------------------")
    logger.info("----------------------End time:%s-------------------"%getCurrentTime())

