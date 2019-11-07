#!/usr/bin/env bash
#
check_network() {
	if ! `ping -c 3 down.op.antuzhi.com &>/dev/null`;then
	   echo -e  "\033[41m####### Please check the network and try again! ######## \033[0m"
	   exit 5
	fi
	}
create_repo() {
	if [[ ${os_version} == 7 ]];then
		rpm -ivh http://down.op.antuzhi.com/apps/el7/epel-release-latest-7.noarch.rpm >/dev/null
	else
		rpm -ivh http://down.op.antuzhi.com/apps/el6/epel-release-latest-6.noarch.rpm >/dev/null
	fi
	}
install_rpms() {
	echo -e  "\033[42m#######Setting base rpm tools######## \033[0m"
	yum -q install lrzsz vim wget zip unzip bash-completion sysstat htop lsof -y
	}
set_date() {
	echo -e  "\033[42m#######Setting date######## \033[0m"
	yum -q install ntp -y
	wget -q http://down.op.antuzhi.com/apps/ntp.conf -O /etc/ntp.conf
	if [[ $os_version == 7 ]];then
		systemctl restart ntpd.service
		systemctl enable ntpd.service
	else	
		service ntpd restart
		chkconfig ntpd on
	fi
	}
set_selinux() {
	echo -e  "\033[42m#######Setting selinux######## \033[0m"
	if [ -f /etc/selinux/config ];then
		sed -i 's#SELINUX=.*#SELINUX=disabled#' /etc/selinux/config
		setenforce 0
	fi
	}
set_sshd(){
	echo -e  "\033[42m#######Setting sshd service######## \033[0m"
	sed -i '/UseDNS/a UseDNS no' /etc/ssh/sshd_config
	sed -i '/GSSAPIAuthentication/ s/yes/no/' /etc/ssh/sshd_config
	if [[ $os_version == 7 ]];then
		systemctl restart sshd.service
	else
		/etc/init.d/sshd restart
	fi
	}
set_firewall() {
	echo -e  "\033[42m#######Setting system firewall######## \033[0m"
	if [[ $os_version == 7 ]];then
		/etc/init.d/iptables stop
		chkconfig iptables off
		systemctl stop firewalld.service
		systemctl disable firewalld.service
	else
		/etc/init.d/iptables stop
		chkconfig iptables off
	fi
	}
set_basesys(){
echo -e  "\033[42m#######Setting basesystem######## \033[0m"
ulimit -SHn 655350
cat >> /etc/security/limits.conf << EOF
*           soft   nofile       655350
*           hard   nofile       655350
EOF
cp /etc/sysctl.conf{,.bak}
cat > /etc/sysctl.conf << EOF
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296 
net.ipv4.tcp_max_tw_buckets = 6000 
net.ipv4.tcp_sack = 1 
net.ipv4.tcp_window_scaling = 1 
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.ipv4.ip_local_port_range = 30000  60999
vm.swappiness=10
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 600
EOF
/sbin/sysctl -p > /dev/null 2>&1
}

set_hostname() {
	echo -e  "\033[42m#######Setting hostname######## \033[0m"
	cd $base_dir
	[ ! -d opbin ] && mkdir opbin
	cd opbin && wget -q http://down.op.antuzhi.com/hostfile -O /data/program/opbin/hostfile 
	h_name=$(grep ${internal_ip} hostfile | awk '{print $2}')
        if [[ $os_version == 7 ]];then
         	hostnamectl set-hostname ${h_name} 
        else
		hostname ${h_name}
		sed -i "s/HOSTNAME=.*/HOSTNAME=${h_name}/" /etc/sysconfig/network
    	fi
	}

install_cloudmonitor() {
	echo -e  "\033[42m#######Install Alimonitor######## \033[0m"
	if ! `ps -ef | grep cloudmonitor | grep -v grep &> /dev/null`;then
		CMS_AGENT_ACCESSKEY=WKqg05FPRiM CMS_AGENT_SECRETKEY=ZBOcYf0PAJ09v2QYERRVDg VERSION=2.1.55 /bin/bash -c "$(curl -s http://cms-download.aliyun.com/cms-go-agent/cms_go_agent_install_necs-1.0.sh)" >/dev/null 2>&1
        fi 
	}

install_superv() {
	echo -e  "\033[42m#######Install Supservisor######## \033[0m"
	yum -q install supervisor -y
	if [[ ${os_version} == 7 ]];then
		systemctl start supervisord.service
		systemctl enable supervisord.service
	else
		/etc/init.d/supervisord start
		chkconfig supervisord on
	fi		
}	

install_za() { 
	echo -e  "\033[42m#######Install zabbix_agent######## \033[0m"
	if [ ! -d ${base_dir}/zabbix_agent ];then
		if [[ ${os_version} == 7 ]];then
			yum -q install gcc gcc-c++ libevent libevent-devel pcre pcre-devel -y
			wget -q http://down.op.antuzhi.com/apps/el7/zabbix_agent.tar.gz -O ${base_dir}/zabbix_agent.tar.gz
			wget -q http://down.op.antuzhi.com/apps/el7/zabbix-agent.service -O /usr/lib/systemd/system/zabbix-agent.service
			systemctl enable zabbix-agent.service
		else
			yum -q install gcc gcc-c++ libevent libevent-devel -y && wget http://down.op.antuzhi.com/apps/el6/libiconv-1.15.tar.gz -O /tmp/libiconv-1.15.tar.gz && cd /tmp/ && tar -zxvf libiconv-1.15.tar.gz && cd /tmp/libiconv-1.15 && /tmp/libiconv-1.15/configure > /dev/null && make > /dev/null && make install > /dev/null && ln -sf /usr/local/lib/libiconv.so.2 /lib/libiconv.so.2 && ln -sf /usr/local/lib/libiconv.so.2 /lib64/libiconv.so.2
			wget -q http://down.op.antuzhi.com/apps/el6/zabbix_agent.tar.gz -O ${base_dir}/zabbix_agent.tar.gz
			wget -q http://down.op.antuzhi.com/apps/el6/zabbix -O /etc/init.d/zabbix
			chmod +x /etc/init.d/zabbix
			chkconfig zabbix on
         	fi
        fi
	cd ${base_dir} && tar -xf zabbix_agent.tar.gz
	sed -i "s/^Hostname=.*/Hostname=${internal_ip}/" /data/program/zabbix_agent/etc/zabbix_agentd.conf
	sed -i "s/^SourceIP=.*/SourceIP=${internal_ip}/" /data/program/zabbix_agent/etc/zabbix_agentd.conf
	if [[ $os_version == 7 ]];then
		systemctl restart zabbix-agent.service
	else	
		service zabbix restart
	fi
}
				
install_nginx() { 
	echo -e  "\033[42m#######Install Nginx######## \033[0m"
	if [ ! -d ${base_dir}/nginx -a ! -d ${base_dir}/nginx-1.14.1 ];then
		yum -q install gcc pcre pcre-devel zlib zlib-devel openssl openssl-devel perl-ExtUtils-Embed GeoIP GeoIP-devel deltarpm -y
		wget -q http://down.op.antuzhi.com/apps/nginx-1.14.1.tar.gz -O /tmp/nginx-1.14.1.tar.gz
		wget -q http://down.op.antuzhi.com/apps/nginx-cofigs.tar.gz -O /tmp/nginx-cofigs.tar.gz
		cd /tmp && tar -xf nginx-1.14.1.tar.gz && cd nginx-1.14.1
		./configure --prefix=/data/program/nginx-1.14.1 --with-http_ssl_module --with-http_stub_status_module --with-pcre --with-threads --with-http_geoip_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_perl_module --with-stream --with-stream_ssl_module --with-stream_geoip_module --with-debug &>/dev/null && make && make install && cd ${base_dir} && ln -sf nginx-1.14.1 nginx
        	if [[ ${os_version} == 7 ]];then
            		wget -q http://down.op.antuzhi.com/apps/el7/nginx.service -O /usr/lib/systemd/system/nginx.service
            		systemctl enable nginx.service
        	else
            		wget -q http://down.op.antuzhi.com/apps/el6/nginx -O /etc/init.d/nginx
		    	chmod +x /etc/init.d/nginx
            		chkconfig nginx on
		fi
	fi
	cd /tmp && tar -xf nginx-cofigs.tar.gz -C ${base_dir}/
    	if [[ $os_version == 7 ]];then
	    systemctl daemon-reload
            systemctl restart nginx.service
   	 else
	    chkconfig nginx on
            service nginx restart
   	 fi
}

install_php() {
	echo -e  "\033[42m#######Install PHP######## \033[0m"
	if [ ! -d ${base_dir}/php -a ! -d ${base_dir}/php-7.2.12 ];then
		yum -q install gcc gcc-c++ openssl openssl-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel mysql pcre-devel bzip2 bzip2-devel libcurl libcurl-devel readline readline-devel -y
		wget -q http://down.op.antuzhi.com/apps/php-7.2.12.tar.gz -O /tmp/php-7.2.12.tar.gz
		wget -q http://down.op.antuzhi.com/apps/php-cofigs.tar.gz -O /tmp/php-cofigs.tar.gz
		cd /tmp && tar -xf php-7.2.12.tar.gz && cd php-7.2.12
		./configure '--prefix=/data/program/php-7.2.12' '--with-config-file-path=/data/program/php-7.2.12/etc' '--enable-inline-optimization' '--disable-debug' '--disable-rpath' '--enable-shared' '--enable-opcache' '--enable-fpm' '--with-fpm-user=baice' '--with-fpm-group=baice' '--enable-mysqlnd' '--with-mysqli=mysqlnd' '--with-pdo-mysql=mysqlnd' '--with-gettext' '--enable-mbstring' '--with-iconv' '--with-mhash' '--with-openssl' '--enable-bcmath' '--enable-soap' '--with-libxml-dir' '--enable-pcntl' '--enable-shmop' '--enable-sysvmsg' '--enable-sysvsem' '--enable-sysvshm' '--enable-sockets' '--with-zlib' '--enable-zip' '--with-bz2' '--with-readline' '--with-gd' &>/dev/null 
		if [[ $? -eq 0  ]];then
			make && make install
			#make ZEND_EXTRA_LIBS='-liconv' && make install
		else
			echo -e "\033[41m#######Make PHP FAILD######## \033[0m"
		fi
		cd /data/program && ln -sf php-7.2.12 php
		wget -q http://down.op.antuzhi.com/apps/redis-5.0.0.tgz -O /tmp/redis-5.0.0.tgz
		cd /tmp && tar -xf redis-5.0.0.tgz && cd redis-5.0.0
		/data/program/php-7.2.12/bin/phpize && ./configure --with-php-config=/data/program/php-7.2.12/bin/php-config && make && make install
		if [[ ${os_version} == 7 ]];then
            		wget -q http://down.op.antuzhi.com/apps/el7/php-fpm.service -O /usr/lib/systemd/system/php-fpm.service
			systemctl daemon-reload
            		systemctl enable php-fpm.service
        	else
            	    wget -q http://down.op.antuzhi.com/apps/el6/php-fpm -O /etc/init.d/php-fpm
		    chmod +x /etc/init.d/php-fpm
                    chkconfig php-fpm on
		fi
	cd /tmp && tar -xf php-cofigs.tar.gz -C ${base_dir}/	 
	fi
}

install_jdk() {
	echo -e  "\033[42m#######Install JDK######## \033[0m"
	wget -q http://down.op.antuzhi.com/apps/jdk18.tar.gz -O /tmp/jdk18.tar.gz
	cd /tmp && tar -xf jdk18.tar.gz -C /data/program
	cp /etc/profile{,.bak}
	cd /data/program && ln -s jdk1.8.0_191 jdk
cat >> /etc/profile <<\EOF
export JAVA_HOME=/data/program/jdk
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export PATH=$JAVA_HOME/bin:$PATH
EOF
source /etc/profile
}

main() {
	os_des=`cat /etc/redhat-release`
	os_arr=(${os_des})
	os_version=`echo ${os_arr[3]} | awk -F. '{print $1}'`
	internal_ip=`ip addr | awk '/inet\>/{print $2}' | awk -F'/' 'NR==2{print $1}'`
	[ ! -d /data/program ] && mkdir -p /data/program
	base_dir=/data/program
        check_network
	create_repo
        install_rpms
	set_date
	set_selinux
	set_sshd
	set_firewall
	set_basesys
	#set_hostname
	install_cloudmonitor
	#install_superv
	#install_za
	#install_nginx
	install_php
	#install_jdk
	}
main
