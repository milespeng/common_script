#!/usr/bin/python
import sys
import urllib2
submail_xsend_url="https://api.submail.cn/message/xsend.json"

def sendsms(mobile,content):
        body ='project=gjyd11&to=%s&signature=61b99c2687687e5f727118d4cc7ffa86&vars={\"code\":\"%s\"}&appid=10373'%(mobile,content)
        urldata = urllib2.urlopen(url=submail_xsend_url,data=body)
        print urldata.read()
if __name__ == '__main__':
        sendsms(sys.argv[1],sys.argv[2])