# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2013
## File : util.py
## Author : filebat <markfilebat@126.com>
## Description :
## --
## Created : <2013-01-25 00:00:00>
## Updated: Time-stamp: <2014-03-29 12:25:54>
##-------------------------------------------------------------------
import hashlib
import config
import json
import fnmatch
import os

import json
from logging.handlers import RotatingFileHandler
import logging
import sys
import socket

format = "%(asctime)s %(filename)s:%(lineno)d - %(levelname)s: %(message)s"
formatter = logging.Formatter(format)

log = logging.getLogger('xzb_webserver')

Rthandler = RotatingFileHandler('xzb_webserver.log', maxBytes=5*1024*1024,backupCount=5)
Rthandler.setLevel(logging.INFO)
Rthandler.setFormatter(formatter)

consoleHandler = logging.StreamHandler()
consoleHandler.setLevel(logging.INFO)
consoleHandler.setFormatter(formatter)

log.setLevel(logging.INFO)
#log.setLevel(logging.WARNING)
log.addHandler(consoleHandler)
log.addHandler(Rthandler)

#  --8<-------------------------- separator ------------------------>8--
fb_log = logging.getLogger('xzb_feedback')

fb_filename="%s/feedback/%s_xzb_feedback.log" % (config.XZB_HOME, socket.gethostname())
fb_Rthandler = RotatingFileHandler(fb_filename, maxBytes=5*1024*1024,backupCount=5)
fb_Rthandler.setLevel(logging.INFO)

fb_log.setLevel(logging.INFO)
fb_log.addHandler(consoleHandler)
fb_log.addHandler(fb_Rthandler)

def wash_content(content):
    ret = content[0:config.MAX_LENGTH]
    if ret[-1] == '\\':
        ret =ret[0:-1]
    return ret

def fill_post_data(post):
    with open(post.filename, 'r') as f:
        content = f.read()

    # TODO: more efficient way
    i = 0
    lines = content.split('\n')
    for line in lines:
        i = i + 1
        if line == config.DATA_SEPARATOR:
            break
    content = '\n'.join(lines[i:])

    content = content.decode('utf-8')
    content = content.replace('\\', '/') # change escape
    content = json_escape(content)
    post.content = content
    return True

def get_meta_dict(fname):
    f = open(fname, 'r')
    content = f.read()
    content = content.decode('utf-8')
    metadata_dict = {}
    for line in content.split('\n'):
        if line == config.DATA_SEPARATOR:
            break
        index = line.find(":")
        length = len(line)
        if index != -1:
            key = line[0:index]
            value = line[index+1:length]
            metadata_dict[key] = json_escape(value).strip()

    if metadata_dict.has_key('meta') is False:
        metadata_dict['meta'] =""

    return metadata_dict

def fill_post_meta(post):
    try:
        metadata_dict = get_meta_dict(post.filename)
        if metadata_dict.has_key("title") and metadata_dict["title"].strip() !="":
            post.title = metadata_dict["title"]
        post.source = metadata_dict["source"]
        post.summary = metadata_dict["summary"]
        post.metadata = metadata_dict["meta"]
    except IOError:
        print "Fail to get filename for post. category:%s, title:%s" % (post.category, post.title)
        return False
    return True

class POST:
    def __init__(self, postid, category, title, filename):
        self.postid = postid
        self.category = category.encode('utf-8')
        self.title = title.encode('utf-8')
        self.summary = ""
        self.source = ""
        self.metadata = ""
        self.content = ""
        self.filename = "%s/%s" % (config.DATA_BASEDIR, filename)

    def print_obj(self):
        print "id:%s, category:%s, title:%s, summary:%s, content:%s, filename:%s, meta:%s\n" % \
            (self.id, self.category, self.title, self.summary, self.content, self.filename, self.meta)

    @staticmethod
    def list_to_post(list_obj):
        return POST(list_obj[0], list_obj[1], list_obj[2], list_obj[3])

    @staticmethod
    def lists_to_posts(lists_obj):
        posts_obj = []
        for list_obj in lists_obj:
            post_obj = POST.list_to_post(list_obj)
            fill_post_meta(post_obj)
            posts_obj.append(post_obj)
        return posts_obj

def json_escape(content):
    ## TODO: to be more efficient
    content = content.replace('"', '\\"')
    content = content.replace('\n', '\\n')
    return content

def smarty_remove_extra_comma(content):
    if content[-2] == ',':
        content = content[0:-2] + content[-1]
    return content
## File : util.py