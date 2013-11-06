#!/usr/bin/env python
'''Scrapes the pager params from a file'''
from __future__ import print_function
import sys
import re
import json

filename = sys.argv[1]

with open(filename, 'r') as file_obj:
    content = file_obj.read()

match = re.search(r"name: '([^']+)'.+nrPages: ([0-9]+).+extra: '([^']+)'",
    content, re.DOTALL)

name = match.group(1)
num_pages = match.group(2)
extra = match.group(3)

print(json.dumps({
    'name': name,
    'num_pages': int(num_pages),
    'extra': extra
}))
