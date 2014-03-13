# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2013
## File : data.py
## Author : filebat <markfilebat@126.com>
## Description :
## --
## Created : <2013-01-25 00:00:00>
## Updated: Time-stamp: <2014-03-12 18:46:40>
##-------------------------------------------------------------------
import config
from util import POST
from util import fill_post_data, fill_post_meta
from sqlalchemy import create_engine

db = None

def create_db_engine():
    global db
    engine_str = "mysql://%s:%s@%s/%s" % (config.DB_USERNAME, \
                                          config.DB_PWD, config.DB_HOST, config.DB_NAME)
    db = create_engine(engine_str)

# sample: data.get_post("ffa72494d91aeb2e1153b64ac7fb961f")
def get_post(post_id):
    global db
    conn = db.connect()

    cursor = conn.execute("select id, category, title from posts where id ='%s'" % post_id)
    out = cursor.fetchall()
    conn.close()
    post = None
    if len(out) == 1:
        post = POST.list_to_post(out[0])
        fill_post_data(post)
        fill_post_meta(post)

    return post

# def list_user_post(userid, date):
#     conn = MySQLdb.connect(config.DB_HOST, config.DB_USERNAME, config.DB_PWD, \
#                          config.DB_NAME, charset='utf8', port=3306)
#     cursor = conn.cursor()
#     if date == '':
#         sql = "select posts.id, posts.category, posts.title " + \
#             "from deliver inner join posts on deliver.id = posts.id " + \
#             "where userid='{0}' order by deliver_date, num desc".format(userid)
#     else:
#         sql = "select posts.id, posts.category, posts.title " + \
#             "from deliver inner join posts on deliver.id = posts.id " + \
#             "where userid='{0}' and deliver_date='{1}' order by deliver_date, num desc".format(userid, date)
#     cursor.execute(sql)
#     out = cursor.fetchall()
#     user_posts = POST.lists_to_posts(out)

#     if date == '':
#         sql = "select posts.id, posts.category, posts.title " + \
#             "from deliver, posts, user_group " +\
#             "where deliver.id = posts.id and user_group.userid='{0}' " +\
#             "and user_group.groupid=deliver.userid " +\
#             "order by deliver_date, num desc; ".format(userid)

#     else:
#         sql = "select posts.id, posts.category, posts.title " + \
#             "from deliver, posts, user_group " +\
#             "where deliver.id = posts.id and user_group.groupid=deliver.userid and " +\
#             "user_group.userid='{0}' and deliver_date='{1}' order by deliver_date, num desc;".format(userid, date)

#     cursor.execute(sql)
#     out = cursor.fetchall()
#     cursor.close()
#     group_posts = POST.lists_to_posts(out)

#     return user_posts + group_posts

def list_topic(topic, start_num, count, voteup, votedown):
    global db
    conn = db.connect()

    extra_where_clause = ""
    if voteup != -1:
        extra_where_clause = "%s and voteup = %d" % (extra_where_clause, voteup)
    if votedown != -1:
        extra_where_clause = "%s and votedown = %d" % (extra_where_clause, votedown)

    sql_format = "select posts.id, posts.category, posts.title from posts where category = '%s' %s order by num desc limit %d offset %d;"
    sql = sql_format % (topic, extra_where_clause, count, start_num)
    print sql
    cursor = conn.execute(sql)
    out = cursor.fetchall()
    conn.close()
    user_posts = POST.lists_to_posts(out)
    return user_posts

## File : data.py
