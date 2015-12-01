#!/bin/bash
logs_path="/var/log/"
back_log="/data/log/haproxy/"

/bin/mv $logs_path/haproxy.log ${back_log}haproxy_log_$(date +"%Y%m%d").log

killall -9 haproxy && /usr/local/haproxy/sbin/haproxy -f /usr/local/haproxy/etc/haproxy.cfg
/etc/init.d/rsyslog restart
