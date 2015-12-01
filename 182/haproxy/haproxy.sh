#!/bin/bash

while true
do
cat <<EOF
	--------HA维护平台------------
	1)HA配置文件检测
	2)HA重启
	3)HA增加,删除服务器
	4)退出
EOF
read -p "请选择:" num
case $num in
1)
	/usr/local/haproxy/sbin/haproxy -c -f /usr/local/haproxy/etc/haproxy.cfg
	if [ $? = 0 ];then
		echo "HA配置文件正确"
	else
		echo "HA配置文件错误，请修改"
	fi
	exit 0
;;
2)
        /usr/local/haproxy/sbin/haproxy -c -f /usr/local/haproxy/etc/haproxy.cfg
        if [ $? = 0 ];then
                echo "HA配置文件正确,马上重启"
		exit 0
        else
                echo "HA配置文件错误,请修改"
        	exit 1
	fi
	killall haproxy && /usr/local/haproxy/sbin/haproxy -f /usr/local/haproxy/etc/haproxy.cfg
	if [ $? = 0 ];then
		echo "HA重启完成,进程列表:"
		ps -ef|grep haproxy|grep -v grep		
		exit 0
	else
		echo "HA重启异常,请检查."
		exit 1
	fi
;;
3)	
	echo	 "1)增加服务器"
	echo	 "2)删除服务器"
	echo	 "3)返回上级菜单"
	echo	 "4)退出"
	read -p "请选择:" num1
	case $num1 in
	1)
		read -p "请输入服务器IP:" ip
		sed -i 
