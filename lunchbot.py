#!/usr/bin/env python3

import sys
import json
import time
import requests

ltf = '/home/pacs/var/lt.json'

if len(sys.argv) < 2:
    url = sys.stdin.readline().strip()
else:
    url = sys.argv[1]

with open(ltf) as f:
    j = json.load(f)

wd = time.strftime('%a').lower()
#print 'wd:', wd
a = []
for i in j[wd]:
    #print 'i:', i
    if i['menu']:
        ai = {'fallback': i['name'] + ': ' + '|'.join(i['menu']),
              'pretext': '<' + i['link'] + '|' + i['name'] + '>',
              'text': '\n'.join(i['menu']),
              'color': '#DAA520',
              "mrkdwn_in": ["text"]}
        a.append(ai)
m = {'text': 'Today\'s lunch suggestions brought to you by <https://mudhead.se/lunch|mudhead lunchtime>',
     'attachments': a}
mstr = json.dumps(m)
#print 'mstr:', mstr
r = requests.post(url, data=mstr)
#print 'r:', r
