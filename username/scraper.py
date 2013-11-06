#!/usr/bin/python
import random
import re
import sys
import time
import traceback
import urllib
import urllib2


user_agent = 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.101 Safari/537.36'


def sleep(seconds=0.75):
    sleep_time = seconds * random.uniform(0.5, 2.0)
    time.sleep(sleep_time)


def pager(hostname, name, page_number, extra):
    '''Makes a request to Hyves pager.'''
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

    return response.read()


def scrape_pager(content):
    '''Scrapes the pager params from html'''
    match = re.search(r"name: '([^']+)'.+nrPages: ([0-9]+).+extra: '([^']+)'",
        content, re.DOTALL)

    name = match.group(1)
    num_pages = match.group(2)
    extra = match.group(3)

    return {
        'name': name,
        'num_pages': int(num_pages),
        'extra': extra
    }


def fetch_content_page(username, category_name):
    print 'Fetch', username, category_name

    headers = {
        'User-Agent': user_agent
    }
    url = 'http://{}.hyves.nl/{}'.format(username, category_name)
    request = urllib2.Request(url, headers=headers)
    response = urllib2.urlopen(request)
    content = response.read()

    pager_params = scrape_pager(content)

    yield content

    print 'Pages=', pager_params['num_pages'], 'Name=', pager_params['name']

    for page_num in xrange(1, pager_params['num_pages'] + 1):
        print 'Page', page_num
        content = pager('{}.hyves.nl'.format(username), pager_params['name'],
            page_num, pager_params['extra'])
        yield content
        sleep()


def fetch_main_content_page(username, pager_name):
    print 'Fetch', username, pager_name

    headers = {
        'User-Agent': user_agent
    }
    url = 'http://{}.hyves.nl/'.format(username, category_name)
    request = urllib2.Request(url, headers=headers)
    response = urllib2.urlopen(request)
    content = response.read()

    pager_params = scrape_pager(content)

    yield content

    print 'Pages=', pager_params['num_pages'], 'Name=', pager_name

    for page_num in xrange(1, pager_params['num_pages'] + 1):
        print 'Page', page_num
        content = pager('{}.hyves.nl'.format(username), pager_name,
            page_num, pager_params['extra'])
        yield content
        sleep()



if __name__ == '__main__':
    username = sys.argv[1]
    filename = sys.argv[2]

    for category_name in ['vrienden', 'leden']:
        with open('{}.{}.txt'.format(filename, category_name), 'w') as out_file:
            try:
                for content in fetch_content_page(username, category_name):
                    out_file.write(content)
            except urllib2.HTTPError:
                traceback.print_exc(limit=1)

    with open('{}.hyves.txt'.format(filename), 'w') as out_file:
        try:
            for content in fetch_main_content_page(username, 'publicgroups_default_redesign'):
                out_file.write(content)
        except urllib2.HTTPError:
            traceback.print_exc(limit=1)
