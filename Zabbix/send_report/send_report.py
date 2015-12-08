#! /usr/bin/python
# -*- coding: UTF-8 -*-
__author__ = 'miles.peng'
import  time,datetime
import  os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import smtplib
import  subprocess
import  sys
import  ConfigParser
import  logging
import boto
from pyh import *
import pdb

def create_files(params,file_postfix_):
    datetime=str(time.strftime('%Y-%m-%d-%H-%M',time.localtime(time.time())))
    output_file="%s/%s_%s.%s"%(params["output_path"],file_postfix_,datetime,"csv")
    db_host=params["db_host"]
    db_user=params["db_user"]
    db_passwd=params["db_passwd"]
    run_sql=params["run_sql"]
    cmd='mysql -h%s -u%s -p%s  -e %s  >%s'%(db_host,db_user,db_passwd,run_sql,output_file)
    if run_cmd(cmd):
        return output_file
    else:
        msg="%s create Failed"%output_file
        logging.error(msg)
        return False

def send_mail_via_aws(params,msg):
    aws_id=params["aws_access_key_id"]
    aws_key=params["aws_secret_access_key"]
    try:
#        pdb.set_trace()
        connection=boto.connect_ses(aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
        result = connection.send_raw_email(msg.as_string(), source=msg['From'] , destinations=msg['To'].split(","))
        msg=result
        logging.info(msg)
        return True
    except Exception, e:
        print str(e)
        return False

def send_mail(mail_host,msg):
    try:
        for mail_to in msg["to"].split(","):
            server = smtplib.SMTP()
            server.connect(mail_host)
    #        s.login(mail_user,mail_pass)
            server.sendmail(msg["from"], mail_to, msg.as_string())
            server.quit()
        return True
    except Exception, e:
        print str(e)
        return False

def row_line_change(attach_file):
    data=[]
    with open(attach_file) as files:
        data=files.readlines()
    dict={}
    for i in range(len(data)):
        for j in range(len(data[0].strip().split("\t"))):
            if i==0:
               # dict[j]=[]
                 dict[data[0].strip().split("\t")[j]]=[]
            else:
                dict[data[0].strip().split("\t")[j]].append(data[i].strip().split("\t")
    [j])
    cmd="rm %s"%attach_file
    run_cmd(cmd)
    first_line=data[0].strip().split("\t")
    file_w=open(attach_file,"a+")
    for row in first_line:
        file_w.write(row)
        file_w.write("\t")
        for line in dict[row]:
            file_w.write(line)
            file_w.write("\t")
        file_w.write("\n")

def construct_mail(params,attach_file):
    #mail_host=params["mail_host"]
    #判断附件内容是否为空
    with open(attach_file) as file:
        data=file.read()
        if len(data.split("\n"))==1:
            contents=params["mail_contents"].split("|")[-1]
        else:
            contents=params["mail_contents"].split("|")[0]

    if params["include_attach"].lower()=="true":
        #以Html方式构造正文内容（include附件）
        msg=MIMEMultipart('alternative')
        if  create_html_contents(contents,attach_file):
            attach_file_html=attach_file[0:-3]+'html'
            with open(attach_file_html) as file:
                html=file.read()
            htm = MIMEText(html,'html','utf-8')
            msg.attach(htm)
        else:
            msg="create html %s Failed"%attach_file
            logging.error(msg)
        if params.get("row_line",False).lower()=="true":
            row_line_change(attach_file_html)
    else:
        #构造正文不包含附件内容
        msg = MIMEMultipart()
        msg.attach(MIMEText(contents , 'plain', 'utf-8'))
    #构造附件1
    att1 = MIMEText(open(attach_file, 'rb').read(), 'base64', 'gb2312')
    basename = os.path.basename(attach_file)
    att1["Content-Type"] = 'application/octet-stream'
    att1["Content-Disposition"] = 'attachment; filename=%s'%basename.decode('utf-8').encode('gb2312')
    msg.attach(att1)
    #加邮件头
   # pdb.set_trace()
    msg['to'] =params["mail_to_list"]
    msg['from'] = params["mail_from"]
    msg['subject'] = params["mail_sub"]
    return msg
    #if send_mail(mail_host,msg):
    # if send_mail_via_aws(params,msg):
    #     return True
    # else:
    #     return  False

def create_html_contents(contents,attach_file):

    #list=[[1,'Lucy',25],[2,'Tom',30],[3,'Lily',20]]
    page = PyH('Aspect')
    page<<div(style="text-align:center")<<h4(contents)
    mytab = page << table(border="1",cellpadding="3",cellspacing="0",style="margin:auto")
    #tr1 = mytab << tr(bgcolor="lightgrey")

    with open(attach_file) as file:
        data=file.read()

    #th_heads=data.split("\n")[0].split("\t")
    #for th_head in th_heads:
     #   tr1 << th(th_head)

    for i in range(len(data.split("\n"))):
        if data.split("\n")[i]:
            tr2 = mytab << tr()
         #   if i != 0:
            for j in range(len(data.split("\n")[i].split(","))):
                tr2 << td(data.split("\n")[i].split(",")[j])
                # if list[i][j]=='':
                #     tr2.attributes['bgcolor']='yellow'
                # if list[i][j]=='100':
                #     tr2[1].attributes['style']='color:red'

    output_file=attach_file[0:-3]+'html'
    page.printOut(output_file)
    #html=page.body
    return True


def run_cmd(cmd):
        print "Starting run: %s "%cmd
        cmdref = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        out = cmdref.stdout.read()
        #print "run cmd  output "+out
        data = cmdref.communicate()
        if cmdref.returncode == 0:
 #           msg = "Run %s success \n" % cmd
 #           msg = msg + data[0]
 #           logging.info(msg)

            return True
        else:
            msg = "[ERROR] Run %s False \n" % cmd
            msg = msg + data[1]
            logging.error(msg)
            logging.error(out)
            sys.exit(1)
            return False

def read_conf(sections,configName):
     cf=ConfigParser.ConfigParser()
     cf.read(configName)
     configDataSection=cf.sections()
     returnData={}
     _common=cf.items("common")

     for _common_key,_common_value in _common:
         returnData[_common_key]=_common_value

     if sections in configDataSection:
         _list=cf.items(sections)
         for _key,_value in _list:
             returnData[_key]=_value
     else:
         print "[ERROR] %s is not in config files,PLS check it %s" %(sections,configName)
         sys.exit(1)
     return returnData

def clear_report(TargPath,expiration):
    fileList=[]
    removeList=[]
    fileList=os.listdir(TargPath)
    for checkfile in fileList:
        filestat=os.stat(TargPath +'/'+checkfile)
        createday=datetime.date.fromtimestamp(filestat.st_ctime)
        today=datetime.date.today()
        if (today - createday).days >= expiration:
            removeList.append(TargPath +'/'+ checkfile)
    if len(removeList) > 0:
        for removeFiles in removeList:
            cmd = "rm %s" % removeFiles
            run_cmd(cmd)
    return True


def init_log():
    # set basic config when printing file;
    try:
        logging.basicConfig(level=logging.INFO,
                            format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
                            datefmt='%a, %d %b %Y %H:%M:%S',
                            filename='/home/aspect/tools/logs/send_report.log',
                           # filename='send_report.log',
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



def main():
    configName=sys.argv[1]
    #sections为配置文件中[]内容，也为输出文件的前缀
    sections=sys.argv[2]
    init_log()
    for _section in sections.split(","):
        params=read_conf(sections=_section,configName=configName)
        attach_file=create_files(params=params,file_postfix_=_section)
        if attach_file:
            clear_report(params["output_path"],params["remain_days"])
            msg=construct_mail(params,attach_file)
            if send_mail_via_aws(params,msg):
                 msg="Send mail to %s success"%params["mail_to_list"]
                 logging.info(msg)
            else:
                 logging.error("Send mail Failed")
        else:
            msg="[ERROR] Run sql create file failed "
            logging.error(msg)

        # if construct_mail(params,attach_file):
        # msg="Send mail to %s success"%params["mail_to_list"]
        #     logging.info(msg)
        # else:
        #     logging.error("Send mail Failed")


if __name__=="__main__":
    main()


