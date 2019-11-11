#!/bin/bash
#Aliyun OSS目录统计

oss_name=($(/root/ossutil64 ls -s | grep "^oss"))
for bucket in ${oss_name[*]};do
	dirarr=($(/root/ossutil64 ls ${bucket}  -d | sed -n '/^oss.*/p' | sed '1d'))
	echo -e ""
	echo -e  "\033[42m----------------------${bucket}--------------------\033[0m"
	for ossdir in ${dirarr[*]};do
		dirsize=$(/root/ossutil64 du ${ossdir} | awk -F: '/total/{print $NF/1024/1024/1024/1024"TB"}')
		echo -e "${ossdir}\t${dirsize}" 
	done
done
