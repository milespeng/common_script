#!/usr/bin/python
# coding=utf-8
# __author__ = 'miles.peng'
import datetime

beginDate="2015-06-12"
endDate="2015-06-20"

def getDays(beginDate,endDate):  
    format="%Y-%m-%d";  
    bd=strtodatetime(beginDate,format)  
    ed=strtodatetime(endDate,format)  
    oneday=datetime.timedelta(days=1)   
    num=datediff(beginDate,endDate)+1   
    li=[]  
    for i in range(0,num):   
        li.append(datetostr(ed))  
        ed=ed-oneday  
    return li  


def datetostr(date):
    return   str(date)[0:10]

def strtodatetime(datestr,format):
    return datetime.datetime.strptime(datestr,format)

def datediff(beginDate,endDate):
    format="%Y-%m-%d";
    bd=strtodatetime(beginDate,format)
    ed=strtodatetime(endDate,format)
    oneday=datetime.timedelta(days=1)
    count=0
    while bd!=ed:
        ed=ed-oneday
        count+=1
    return count

def getComm(li):
    command01=""
    command02="" 
    c1=[]
    c2=[]   
    for i in li:        
        command01="ALTER TABLE log_playerdailylogin ADD PARTITION (p_date = '%s') location '/userdata/playerdailylogin/p_date=%s';" % (i,i)
        c1.append(command01)
        command02="ALTER TABLE log_revenue ADD PARTITION (p_date = '%s') location '/userdata/revenue/p_date=%s';" % (i,i)
        c2.append(command02)
    return (c1,c2)


if __name__ == '__main__':
    li=getDays(beginDate,endDate)
    c1,c2=getComm(li)
    file=open("command.log","a+")
    for a in range(len(c1)):
        file.write(c1[a]+"\n")
    for b in range(len(c2)):
         file.write(c2[b]+"\n")
print "Mission Complete"

