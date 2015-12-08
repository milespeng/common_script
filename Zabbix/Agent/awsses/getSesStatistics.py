#!/usr/bin/python
import boto.ses
import re
import datetime
import sys

today = datetime.datetime.now().strftime('%Y-%m-%d')
conn = boto.ses.connect_to_region(
    'us-east-1',
    aws_access_key_id='AKIAIXNXIMKN7UGIJ7EA',
    aws_secret_access_key='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',
)

jsonOutput = conn.get_send_statistics()

todayList = []

for i in  jsonOutput['GetSendStatisticsResponse']['GetSendStatisticsResult']['SendDataPoints']:
	if re.search(today,i['Timestamp']):
		todayList.append(i)

todayList.sort(key=lambda todayListSort : todayListSort['Timestamp']) 

if int(todayList[-1:][0]['DeliveryAttempts']) != 0:
	wow = round(int(todayList[-1:][0]['Bounces'])/int(todayList[-1:][0]['DeliveryAttempts']), 2)
else:
	wow = 0

print wow
