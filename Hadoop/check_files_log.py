__author__ = 'miles.peng'
import os
import logging
import  subprocess
import  sys
import pdb
import datetime
expiration=30

def shell_run(dir_list):
    for TargPath in dir_list:
        clear_log(TargPath)


def cmd_run(cmd):
    if cmd=="rm -rf /":
        logging.error("Cann`t remove /")
        sys.exit(1)
    process=subprocess.Popen(cmd,shell=True,stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    output, unused_err = process.communicate()
    retcode = process.poll()
    if retcode:
        logging.error(cmd)
        logging.error(output)
        sys.exit(1)
    else:
        pass
        #logging.info(output)



def init_log():
    # set basic config when printing file;
    try:
        logging.basicConfig(level=logging.INFO,
                            format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
                            datefmt='%a, %d %b %Y %H:%M:%S',
                            filename='check_files.log',
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


def check_path(path,check_type):
    get_check_dirs=[]
    for root,dirs,files in os.walk(path):
#        pdb.set_trace()
        for dir in dirs:
            if dir.lower()==check_type:
                get_dirs=os.path.join(root,dir)
                #logging.info(get_dirs +"\n")
                get_check_dirs.append(get_dirs)
    return get_check_dirs

def clear_log(TargPath):
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
            logging.info(cmd)
            cmd_run(cmd)
    return True


if __name__=="__main__":
    #path=sys.argv[1]
    path="/opt"
    check_type="logs"
    init_log()
    dir_list=[]
    dir_list=check_path(path,check_type)
    shell_run(dir_list)