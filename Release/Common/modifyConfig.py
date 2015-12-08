#!/usr/bin/python
# coding=utf-8
#__author__ = 'miles.peng'


import sys,subprocess,re
import time
import ConfigParser
import logging
import pdb


#CurrTime = time.strftime('%Y-%m-%d_%H:%M', time.localtime(time.time()))

def init_log():
    # set basic config when printing file;
    try:
        logging.basicConfig(level=logging.INFO,
                            format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
                            datefmt='%a, %d %b %Y %H:%M:%S',
                            filename='/home/qa/miles/log/modiconf.log',
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

class Modiconfig():

  def change_conf(self,conFileName,sourData,targData):
        #pdb.set_trace()
        cmd="sed -i '/%s/Is#=.*$#%s#' %s" %(sourData.strip()+'=',('='+targData),conFileName)
        #logging.info(cmd)
    #    pdb.set_trace()
        p = subprocess.Popen(cmd,shell=True,stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        while True:
            buff = p.stdout.readline()
            if buff == '':
                break
            else:
                if p.poll()==0:
                    logging.info(buff)
                else:
                    logging.error(buff)

  
  def read_conf(self,fileName):
        cf=ConfigParser.ConfigParser()
        cf.read(fileName)   
        ConfigDataSection=cf.sections()
        commonSourData=[]
        commonTargData=[]
        conFileName=""
        returnData={}
        
    #    pdb.set_trace()
        #get common date useing in all files
        if "common" in ConfigDataSection:
            commonAllData=cf.items("common")
            ConfigDataSection.remove("common")
            for a,b in commonAllData:
                commonSourData.append(a)
                commonTargData.append(b)             

        for sectionsName in ConfigDataSection:
            itemData = cf.items(sectionsName)
            sectionSourData=[]
            sectionTargData=[]
            
            for a,b in itemData:
                sectionSourData.append(a)
                sectionTargData.append(b)
            #pdb.set_trace()
            for i in range(len(commonSourData)):
                sectionSourData.append(commonSourData[i])
                sectionTargData.append(commonTargData[i])   
            
            conFileName=sectionsName
            
            #pdb.set_trace()
            
            if len(commonSourData) != len(commonTargData):
                msg= "Please check config files content ,source Data length isn`t same as Targer Data"
                logger.error(msg)
                break
            else:
                returnData[conFileName]=(sectionSourData,sectionTargData)

            
        return returnData
            



if __name__ == "__main__":
    argNum = len(sys.argv)
    if argNum != 2:
        message = "Parameter is :{Config files Path&Name}"
        print message
        exit(0)    
    fileName=sys.argv[1]
    init_log() 
    logger=logging.getLogger('main') 
    newConfig=Modiconfig()
    logger.info("-------------------Staring-------------------------")  
    returnData=newConfig.read_conf(fileName.split())
    #pdb.set_trace()
    for conFileName in returnData:
        (sectionSourData,sectionTargData)=returnData[conFileName]
        for i in range(len(sectionSourData)):
            newConfig.change_conf(conFileName,sectionSourData[i],sectionTargData[i])    
    logger.info("-------------------Ending-------------------------")