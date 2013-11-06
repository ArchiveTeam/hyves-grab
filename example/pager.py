#!/usr/bin/env python
'''Makes a request to Hyves pager

http://hyves.nl/statics/pager.js
'''
from __future__ import print_function
import sys
import urllib
import urllib2


hostname = sys.argv[1]
name = sys.argv[2]
page_number = sys.argv[3]
extra = sys.argv[4]
user_agent = 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.101 Safari/537.36'
url = 'http://{}/index.php?xmlHttp=1&module=pager&action=showPage&name={}'\
    .format(hostname, name)
post_data = {
    'pageNr': page_number,
    'config': 'hyvespager-config.php',
    'showReadMoreLinks': 'false',
    'extra': extra
}
headers = {
    'User-Agent': user_agent
}

request = urllib2.Request(url, urllib.urlencode(post_data), headers)

response = urllib2.urlopen(request)

print(response.read())
