#!/bin/bash
sum=0
for i in `cat /root/haproxy.txt`
do
sum=`expr $sum + $i`
echo $sum
done
