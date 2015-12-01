#!/bin/bash
Num=`ps -C haproxy --no-header |wc -l`
if [ $Num -eq 0 ];then
/usr/local/haproxy/sbin/haproxy -D -f /usr/local/haproxy/etc/haproxy.cfg
sleep 3
if [ `ps -C haproxy --no-header |wc -l` -eq 0 ];then
service keepalived stop
fi
fi
