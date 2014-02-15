#!/bin/bash -e
##-------------------------------------------------------------------
## File : show_demo.sh
## Author : filebat <filebat.mark@gmail.com>
## Description :
## --
## Created : <2014-02-04>
## Updated: Time-stamp: <2014-02-14 10:48:39>
##-------------------------------------------------------------------
strs="algorithm product concept story"
lists=($strs)
for item in ${lists[*]}; do
    open "http://127.0.0.1:9081/list_topic?start_num=0&count=10&topic=$item"
done
## File : show_demo.sh ends