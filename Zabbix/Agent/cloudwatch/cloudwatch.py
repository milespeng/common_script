#!/usr/bin/python
__author__ = 'jerry.liu'
import datetime
import sys
import re
import os
import ConfigParser
import pdb

def gettime():
    now = datetime.datetime.now()
    now_strf = now.strftime('[%Y-%m-%d %H:%M:%S]')
    delta_5 = datetime.timedelta(minutes=5)
    now_5 = now - delta_5
    delta_1 = datetime.timedelta(minutes=1)
    now_6 = now_5 - delta_1
    end_time = now_5.strftime('%Y-%m-%dT%H:%M:%S')
    start_time = now_6.strftime('%Y-%m-%dT%H:%M:%S')
    return (end_time,start_time,now_strf)

def getcloudwatchdata(parameter):
    logfile = open('/home/aspect/tools/logs/cloudwatch.log','a+')
    (end_time,start_time,now)=gettime()
    logfile.write(now+' '+str(parameter)+'\n')
    config = ConfigParser.ConfigParser()
    config.readfp(open('/home/aspect/tools/conf/cloudwatch.ini','rb'))
    try:
        profile = config.get(parameter,'profile')
        metric = config.get(parameter,'metric')
        namespace = config.get(parameter,'namespace')
        statistics = config.get(parameter,'statistics')
        Name = config.get(parameter,'Name')
        Value = config.get(parameter,'Value')
    except Exception,e:
        msg = "Can't find section:",e
        logfile.write(now+' ERROR '+str(msg)+'\n')
        exit(1)
    data = '/usr/local/bin/aws --profile '+profile+ ' cloudwatch get-metric-statistics --metric-name '+metric+' --start-time '+start_time+' --end-time '+end_time+' --period 60 --namespace '+namespace+' --statistics '+statistics+' --dimensions Name='+Name+',Value='+Value+'|tail -1|awk -F \' \' \'{print $2}\''
    #print "AWS command line:%s" % data
#    pdb.set_trace()
    try:
        logfile.write(now+' execute '+data+'\n')
        action = os.popen(data)
    except Exception,e:
        msgerr = "command ERROR",e
        logfile.write(now+' '+str(msgerr)+'\n')
        exit(1)

    result = action.read().strip()

    if re.search('Diskfree',parameter):
        Totalstore = config.get(parameter,'Totalstore')
        Totalstore_bytes = int(Totalstore)*1024*1024*1024
        percent_free = round(float(result))/Totalstore_bytes*100
        result_format = str(round(percent_free,2))

    elif re.search('HTTP',parameter) and result == '':
        result_format = '0'
 
    else:
        result_format = str(result)

    logfile.write(now+' '+result_format+'\n')
    
    try:
        print result_format
        os.system('echo %s > /home/aspect/tools/conf/cloudwatch/%s' % (result_format,parameter))
    except Exception,e:
        logfile.write(now+' ERROR result_format '+e+'\n')
        exit(1)

if __name__ == '__main__':
    if len(sys.argv) != 1 and len(sys.argv) != 2:
        print 'Usage: <yourscript> <secetion>'
        print " example: python "+sys.argv[0]+" sg-RDS-production-ml-DBconn"
        exit(1)

    if len(sys.argv) == 2:
        getcloudwatchdata(sys.argv[1])

    if len(sys.argv) == 1:
        config = ConfigParser.ConfigParser()
        config.readfp(open('/home/aspect/tools/conf/cloudwatch.ini','rb'))
        all_secetions = config.sections()
        for secetion in all_secetions:
            print secetion
            getcloudwatchdata(secetion)
