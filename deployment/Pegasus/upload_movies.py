#!/usr/bin/python
__author__ = 'miles.peng'
import subprocess
import logging
import os
import sys
import datetime
import time
import hashlib
import io
import pdb

log_file="/home/qa/deployment/log/upload_movies.log"
ftp_dir="/home/lotustv/data"
pegasus_local="/srv/pegasus_movie"
pegasus_remote="s3://aspectgaming-qmaster/prod_pegasus/movie"
re_sync_s3_count=2
movie_name="play.mp4"

def calMD5(afile):
   m = hashlib.md5()
   file = io.FileIO(afile,'r')
   bytes = file.read(1024)
   while(bytes != b''):
        m.update(bytes)
        bytes = file.read(1024)
   file.close()
   md5value = m.hexdigest()
   return  md5value

def run_cmd(cmd):
        print "Starting run: %s "%cmd
        cmdref = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        out = cmdref.stdout.read()
        data = cmdref.communicate()
        if cmdref.returncode == 0:
            msg="Run %s success"%cmd
            logging.info(msg)
            logging.info(out)
            return True
        else:
            msg = "Run %s False \n" % cmd
            msg = msg + data[1]
            logging.error(msg)
            logging.error(out)
            sys.exit(1)
            return False

def init_log():
    # set basic config when printing file;
    try:
        logging.basicConfig(level=logging.INFO,
                            format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
                            datefmt='%a, %d %b %Y %H:%M:%S',
                            filename=log_file,
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

def check_dir(dir):
    fileList=[]
    fileList=os.listdir(dir)
    return fileList

def re_s3_sync():
    count=0
    while count<=re_sync_s3_count:
        if not  sync_2_s3(pegasus_local,pegasus_remote):
            time.sleep(180)
            count+=1
        else:
            return True
    return False

def sync_2_s3(local_dir,remote):
    cmd="s3cmd sync -P --add-header=Cache-Control:no-cache --recursive %s/ %s/"%(local_dir,remote)
    if run_cmd(cmd):
        return  True
    else:
        return  False

def today_day(param):
    if param=="day":
         current_day=datetime.datetime.now()+datetime.timedelta(hours=8)
         today=int(current_day.weekday())+1
         return  today
    elif param=="hour":
         current_day=datetime.datetime.now()
         hour=current_day.hour
         return  hour
    else:
        msg='Param must in "day" or "hour" '
        logging.error(msg)

def unzip_clear():
    cmd_unzip="cd %s && unzip -o -d %s %s"%(ftp_dir,pegasus_local,"movies.zip") 
    #pdb.set_trace()
    if run_cmd(cmd_unzip):
        cmd_clear="cd %s && rm -f *"%ftp_dir
        if run_cmd(cmd_clear):
            return True
    return False

def updated():
    ftp_list=check_dir(ftp_dir)
    #pdb.set_trace()
    if "movies.zip" in ftp_list and "movies.md5" in ftp_list:
        with open(ftp_dir+"/movies.md5") as files:
            get_md5=files.read().strip()
        check_md5=calMD5(ftp_dir+"/movies.zip")
        print("get_md5=",get_md5);
        print("check_md5=",check_md5);
        if get_md5.strip()==check_md5:
            if unzip_clear():
                return True
        else:
            msg="MD5 calculation is`t same as values in movies.md5"
            logging.error(msg)
            sys.exit(1)
    else:
        msg="movies.zip and movies.md5 is not find in ftp_dir"
        logging.info(msg)
        return False

def sync():
    today_file=pegasus_local+"/"+str(today_day("day"))+".mp4"
    target_file=pegasus_local+"/play.mp4"
    cmd="cp -f %s %s"%(today_file,target_file)
    if run_cmd(cmd):
        rename_msg="Rename %s to %s success"%(today_file,target_file)
        logging.info(rename_msg)
        re_s3_sync()
        msg="Sync Local files to S3 Success"
        logging.info(msg)
    else:
        msg="ERROR remove play.mp4 Failed"
        logging.error(msg)
        sys.exit(1)

def check_time():
    if str(today_day("hour"))=="16":
        return True
    else:
        return False

def backup_pkg(local_dir,remote):
    cmd="s3cmd sync -P --add-header=Cache-Control:no-cache --recursive --delete-removed %s/ %s/bak/"%(local_dir,remote)
    if run_cmd(cmd):
        return  True
    else:
        return  False
	
def main():
    init_log()
    if updated() or check_time():
        backup_pkg(pegasus_local,pegasus_remote)
        sync()
    else:
        msg="Not find files need upload"
        logging.info(msg)
    if check_time():
        msg="\n================================================="
        logging.info(msg)

if __name__=="__main__":
    main()
