title: openvpn 搭建
tags:
  - Linux-service
date: 2019-11-06 08:57:43
---
+ **OpenVPN 部署环境适用于办公室与企业IDC机房内网之间访问模式**
  - centos7 单机部署
  - 分为搭建、OpenVPN配置及证书文件生成、客户端安装配置

###### 
<!--more-->

1.1 部署环境
```bash 部署基本环境
centos7.4 os
10.8.0.0/24							# openvpn 虚拟网卡IP
eth0:192.168.109.170/24 	eth1:172.16.10.100	 	# 网卡IP
```
1.2 安装前准备
```bash 时间同步
yum -y install ntp
systemctl restart ntpd && systemctl enable ntpd
ntpdate server ntp1.aliyun.com
```
###### 

2.1 安装
```bash 安装OpenVPN相关程序包和依赖
yum -y install epel-release
yum clean all && yum repolist
yum -y install openssh-server easy-rsa iptables-services lzo openssl openssl-devel openvpn NetworkManager-openvpn openvpn-auth-ldap zip unzip iptables
```
```bash 拷贝配置
# 拷贝server.conf模板主配置文件
cp /usr/share/doc/openvpn-2.4.9/sample/sample-config-files/server.conf /data/application/openvpn/

# 拷贝easy-rsa程序
cp -R /usr/share/easy-rsa/ /data/application/openvpn/
cd /data/application/openvpn/easy-rsa/3
```
###### 

3.1 初始化私钥
```bash easyrsa初始化私钥，3.0版本和2.0版本有变化。可以不定义var变量
./easyrsa init-pki						# 初始化 pki
./easyrsa build-ca nopass					# 生成 CA 根证书
	# nopass 表示不需要密码
	# Common Name (eg: your user, host, or server name) [Easy-RSA CA]:inadm
./easyrsa build-server-full server nopass			# 创建服务器证书
	# server 为证书名称
./easyrsa gen-dh						# 生成dh密码算法
openvpn --genkey --secret ta.key				# 防止 DoS 和 TLS 攻击;可选项
```
```bash 生成的证书整理到指定目录
mkdir -p mkdir -p /data/application/openvpn/server/certs
cd /data/application/openvpn/server/certs
cd /etc/openvpn/server/certs/
cp pki/dh.pem ../../server/certs/				# SSL协商时dh算法需要key
cp pki/ca.crt ../../server/certs/				# ca 根证书
cp pki/issued/server.crt ../../server/certs/			# openvpn服务器证书
cp pki/private/server.key ../../server/certs/			# openvpn 服务器key证书
cp ta.key ../../server/certs/					# tls-auth key
```

###### 

4.1 创建OpenVPN日志目录
```bash
mkdir -p /data/logs/openvpn
chown openvpn:openvpn /data/logs/openvpn
```

###### 

5.1 配置OpenVPN主配置文件
```bash Client端请求行为主要根据server.conf主配置文件配置所执行
# vim /data/application/openvpn/server.conf
32 port 1194							# 监听的端口号
36 proto udp							# 使用udp协议
78 ca /data/application/openvpn/server/certs/ca.crt		# ca根证书路径
79 cert /data/application/openvpn/server/certs/server.crt	# openvpn服务器证书路径
80 key /data/application/openvpn/server/certs/server.key	# openvpn服务器秘钥路径
85 dh /data/application/openvpn/server/certs/dh.pem		# dh密码算法文件路径
244 tls-auth /data/application/openvpn/server/certs/ta.key 0
101 server 10.8.0.0 255.255.255.0				# openvpn网段,不要和lan冲突
141 push "route 172.16.10.0 255.240.0.0"			# 允许lan地址范围
192 ;push "redirect-gateway def1				# 如开启此行配置,客户端所有流量都通过openvpn转发,全局代理模式
200 push "dhcp-option DNS 1.1.1.1"				# dns服务器配置,idc内部环境有dns服务器,可填内部dns ip
201 push "dhcp-option DNS 223.5.5.5"
222 duplicate-cn						# 允许一个用户多个终端连接
231 keepalive 10 120						# 每10秒ping一次,120 ping不通则重新连接
263 comp-lzo							# 开启openvpn 连接压缩,服务端开启则客户端也需开启
281 persist-key							# 通过keepalive检测超时后,重新启动vpn，不重新读取keys，保留第一次使用的keys
282 persist-tun							# 通过keepalive检测超时后,重新启动vpn，一直保持tun或tap设备是linkup,否则网络连接会先linkdown然后linkup
274 user openvpn						# openvpn启动用户
275 group openvpn
287 status /data/logs/openvpn/openvpn-status.log
306 verb 3
315 explicit-exit-notify 1
316 log /data/logs/openvpn/openvpn.log				# 指定log文件位置
317 log-append /data/logs/openvpn/openvpn-level.log		# 日志记录级别
```
```bash
# redirect-gateway 重点描述
1. 如果启用该行,只要访问互联网全部流量都走openvpn通道,会严重影响访问互联网速度
2. 如果禁用该行,客户端访问lan<内网>时走指定push "route 172.16.10.0/24" 指定网络通道

# duplicate-cn 
1. 如果启用该行,表示可以多个人同时使用
2. 如果禁用该行,表示只能1个人使用,当第2个人登录时,会挤掉前面登录的人
```

###### 

6.1 启用IP转发和iptables防火墙配置
```bash IP 转发
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

# openvpn加速参数
echo -e "net.core.rmem_default = 393216" >> /etc/sysctl.conf
echo -e "net.core.wmem_default = 393216" >> /etc/sysctl.conf
sysctl -p
```
```bash Iptables 防火墙规则配置
systemctl start iptables && systemctl enable iptables
iptables -F
# 将openvpn的网络流量转发到公网snat规则
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j MASQUERADE
-A INPUT -p udp -m state --state NEW -m udp --dport 1194 -j ACCEPT
iptables-save > /etc/sysconfig/iptables
systemctl restart iptables
```

###### 

7.1 启动 OpenVPN 
```bash
# cat > /usr/lib/systemd/system/openvpn.service << _EOF_
[Unit]
Description=OpenVPN Service
After=network.target
    
[Service]
Type=forking
ExecStart=/usr/sbin/openvpn --daemon --config /data/application/openvpn/server.conf
ExecStop=/bin/kill -s QUIT $MAINPID
TimeoutStopSec=0
SendSIGKILL=on

[Install]
WantedBy=multi-user.target
_EOF_
# systemctl daemon-reload
# systemctl start openvpn && systemctl enable openvpn
# # netstat -nlput|grep 1194
```

###### 


7.1 OpenVPN 客户端证书文件创建
```bash 通过脚本整合为1个证书配置文件
# 批量创建和删除OpenVPN用户并合并证书文件
# mkdir -p /root/vpn-clinet/ovpn_bak/				# 创建的证书存放位置
# touch /root/vpn-clinet/ovpn_user.txt				# 需要创建证书的用户,每行一个
# vim /root/vpn-clinet/get_ovpn.sh				# 创建执行的脚本

#!/bin/bash
# Desc: OpenVPN Cert File Create、Logout、Delete


ADD_CRT_DIR='/data/application/openvpn/easy-rsa/3/'
OVPN_File_DIR='/root/vpn-clinet/ovpn_bak/'
OVPN_USER_IF='/data/application/openvpn/easy-rsa/3/pki/index.txt'
WAN_LOCALIP=$(/sbin/ip a|egrep '172.16.|192.168.'|grep -v '192.168.122.1'|awk '{print $2}'|awk -F/ '{print $1}'|head -1)

# New user file judgment
if [ -z $1 ]; then
    echo "请输入参数'ovpn_user.txt'"
    exit 1
elif [ $1 != 'ovpn_user.txt' ] && [ $1 != '/root/vpn-clinet/ovpn_user.txt' ]; then
    echo "输入参数错误,'ovpn_user.txt'相对路径或绝对路径名错误."
    exit 2
else
    OVPN_USER_FILE=`cat $1`
fi

# Merge OpenVPN certificate files
function create_ovpn_cert {
    cd ${ADD_CRT_DIR}
    ./easyrsa build-client-full $OUser nopass &> /dev/null
    echo -e "client\nproto udp\ndev tun\nsndbuf 393216\nrcvbuf 393216\nremote $WAN_LOCALIP 1194\nresolv-retry infinite\npersist-key\npersist-tun\nkey-direction 1\ncomp-lzo\nverb 3" > $OVPN_File_DIR/$OUser.ovpn
    echo '<ca>' >> $OVPN_File_DIR/$OUser.ovpn ; cat pki/ca.crt >> $OVPN_File_DIR/$OUser.ovpn ; echo '</ca>' >> $OVPN_File_DIR/$OUser.ovpn
    echo  '<cert>' >> $OVPN_File_DIR/$OUser.ovpn ; cat pki/issued/$OUser.crt >> $OVPN_File_DIR/$OUser.ovpn ; echo '</cert>' >> $OVPN_File_DIR/$OUser.ovpn
    echo '<key>' >> $OVPN_File_DIR/$OUser.ovpn ; cat pki/private/$OUser.key >> $OVPN_File_DIR/$OUser.ovpn ; echo '</key>' >> $OVPN_File_DIR/$OUser.ovpn
    echo '<tls-auth>' >> $OVPN_File_DIR/$OUser.ovpn ; grep -v '^#' /etc/openvpn/server/certs/ta.key >> $OVPN_File_DIR/$OUser.ovpn ;  echo '</tls-auth>' >> $OVPN_File_DIR/$OUser.ovpn
    echo "${OUser} Create success."
}

function add_user {
    # Create OpenVPN users in batches
    for OUser in ${OVPN_USER_FILE} ;do
        EXISTED_USER=`grep "$OUser" "${OVPN_USER_IF}" | awk -F= '{print $2}'`
        if [ -z $EXISTED_USER ]; then
            create_ovpn_cert
        else
            echo "$OUser用户已存在."
            exit 3
        fi
    done
}

function del_user {
    for OUser in ${OVPN_USER_FILE} ;do
    	cd ${ADD_CRT_DIR}
    	echo -e 'yes\n' | ./easyrsa revoke ${OUser} &> /dev/null
    	./easyrsa gen-crl &> /dev/null
    	rm -f ${ADD_CRT_DIR}pki/issued/${OUser}.crt
    	rm -f ${ADD_CRT_DIR}pki/private/${OUser}.key
    	echo "${OUser} Delete success."
done
}

PS3="Run command: "
select choice in add_user del_user exit
do
    case $choice in
        add_user)
           $choice
           exit
           ;;
        del_user)
           $choice
           exit
           ;;
        exit)
           echo "Bye~"
           exit
           ;;
    esac
done
```

###### 


8.1 客户端连接
```bash Linux 客户端连接命令
openvpn --config ~/path/to/client.ovpn
```

```bash Windows 客户端连接
1. PC客户端官方下载链接: https://openvpn.net/community-downloads/				   # 图1
2. Windows 10 OpenVPN安装: Next > I Agree > Next > Install > Next > Finish
  桌面"OpenVPN GUI"右键属性 > 选择"兼容性"： 勾选"以管理员身份运行此程序" > 应用.确定		   # 图2
3. 将服务器上创建的客户端证书文件放到OpenVPN客户端指定目录下: C:\Program Files\OpenVPN\config	   # 图3
4. PC客户端即可正常连接到内网。如登录报错可右键显示日志,查看报错原因	
```
![upload successful](/images/pasted-8.png)

![upload successful](/images/pasted-9.png)

![upload successful](/images/pasted-10.png)

![upload successful](/images/pasted-11.png)

```bash Android客户端连接 [IOS中国大陆已下架APP]
openvpn安卓包下载: https://apps.evozi.com/apk-downloader/?id=net.openvpn.openvpn		 # 由于openvpn安卓端下载需要设备登录google账号才能正常将apk包下载;为能正常将apk包下载并发送到其它设备正常安装,故通过此方式将包Download下来
   贴此链接进去: https://play.google.com/store/apps/details?id=net.openvpn.openvpn	 # Google Play商店OpenVPN安装包链接
2. 将下载下来的Android包传到手机安装
3. 将证书文件传到手机直接打开证书文件<合并后的证书文件>选择应用程序OpenVPN,即可自动配置相关信息,直接连接即可。
```
```bash Mac OS客户端连接
1. 安装不用介绍
2. 证书配置基本和Windows类似。不一样的地方是没有config配置文件,在安装目录新建一个conf配置文件夹将证书文件放进去即可
3. 下载链接: https://tunnelblick.net/index.html
```
![upload successful](/images/pasted-12.png)

######