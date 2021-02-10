title: namedmanager dns 搭建
tags:
  - Linux-service
date: 2019-09-05 07:46:57
---
+ **NamedManager 基于web的dns服务**

###### 
<!--more-->

1. **数据库及所需软件安装**

```bash mysql 5.7
yum -y remove mariadb-libs						# 移除cnetos7 系统自带的mariadb库
wget https://repo.mysql.com//mysql80-community-release-el7-3.noarch.rpm
rpm -ivh mysql80-community-release-el7-3.noarch.rpm
sed -i '28c enabled=0' /etc/yum.repos.d/mysql-community.repo
sed -i '21c enabled=1' /etc/yum.repos.d/mysql-community.repo
yum clean all && yum repolist
yum -y install mysql-server
```
```bash 修改数据库密码
systemctl start mysqld && systemctl enable mysqld
grep "password" /var/log/mysqld.log
mysql -uroot -p
mysql> set global validate_password_policy=0;
mysql> set global validate_password_length=6;
mysql> alter user user() identified by 'Zd6Uv8QJiLKj';
```

###### 

2. **安装 httpd php-msyql php [namedmanager-www namedmanager-bind](https://repos.jethrocarr.com/)**

```bash named主程序安装
wget -O /etc/yum.repos.d/jethrocarr-c7-public.repo http://repos.jethrocarr.com/config/centos/7/jethrocarr-c7-public.repo
yum clean all && yum repolist
yum -y install namedmanager-www namedmanager-bind php-mysql httpd php
```

![upload successful](/images/pasted-27.png)

###### 

3. **安装bind bind-chroot**

```bash dns包安装
yum -y install bind bind-chroot
```
```bash 初始化chroot环境
/usr/libexec/setup-named-chroot.sh /var/named/chroot on		# setup-named-chroot.sh会自动挂载到chroot目录
systemctl start named-chroot && systemctl enable named-chroot
ll /var/named/chroot/etc					# 检查目录是否挂载成功
ll /var/named/chroot/var/named
```

###### 

4. **主配置文件设置**

```bash 创建主配置文件中的所需文件及赋权
touch /var/named/chroot/var/named/data/cache_dump.db
touch /var/named/chroot/var/named/data/named_stats.txt
touch /var/named/chroot/var/named/data/named_mem_stats.txt

chmod -R 777 /var/named/chroot/var/named/data
chmod -R 777 /var/named/chroot/var/named/dynamic
ln /etc/named.namedmanager.conf /var/named/chroot/named.namedmanager.conf
chown named:named /etc/named.namedmanager.conf
```
```bash 配置文件修改
# cat /var/named/chroot/etc/named.conf
options {
        listen-on port 53        { any; };
        directory               "/var/named";
        dump-file               "/var/named/data/cache_dump.db";
        statistics-file         "/var/named/data/named_stats.txt";
        memstatistics-file      "/var/named/data/named_mem_stats.txt";
        recursing-file          "/var/named/data/named.recursing";
        secroots-file           "/var/named/data/named.secroots";
        allow-query             { any; };
        recursion yes;

        bindkeys-file           "/etc/named.iscdlv.key";
        managed-keys-directory  "/var/named/dynamic";
        pid-file                "/run/named/named.pid";
        session-keyfile         "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
        type hint;
        file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
include "/etc/named.namedmanager.conf";
```
```bash php连接配置
# cat /etc/namedmanager/config-bind.php
...
$config["api_url"]              = "http://172.16.10.90/namedmanager";
$config["api_server_name"]      = "dns.inadm.com";				# api_server_name字段必须与httpd主配置文件中的ServerName一致
$config["api_auth_key"]         = "cbdamxidn";					# 自定义密钥
# chroot环境还需配置如下2行
$config["bind"]["config"]               = "/var/named/chroot/etc/named.namedmanager.conf";
$config["bind"]["zonefiledir"]          = "/var/named/chroot/var/named/";
...
```
```bash http配置文件修改
# cat /etc/httpd/conf/httpd.conf
...
95 ServerName dns.inadm.com:80							# 修改此行
#    Require all denied								# 注释此行
...

# 修改浏览器访问方式为(https://172.16.10.90)
# sed -i '119c DocumentRoot "/usr/share/namedmanager/htdocs/"' /etc/httpd/conf/httpd.conf
```

###### 

5. **导入namedmanager到MySQL**

```bash
# cd /usr/share/namedmanager/resources/
# ./autoinstall.pl
Please enter MySQL root password (if any): Zd6Uv8QJiLKj	
```

![upload successful](/images/pasted-30.png)

###### 

6. **重启服务**

```bash 重启服务
systemctl start httpd && systemctl enable httpd
systemctl restart mysqld
systemctl restart named-chroot
```

###### 

7. **web 页面配置**

```bash 登陆
https://172.16.10.90
    user: setup
    pass: setup123
```
![upload successful](/images/pasted-31.png)

![upload successful](/images/pasted-32.png)

- **添加正向解析**

![upload successful](/images/pasted-33.png)

- **添加Name Server FQDN**
  - "Name Server FQDN"字段要与httpd的ServerName字段一致
  - "API Authentication Key"字段要与php配置文件"api_auth_key"字段一致

![upload successful](/images/pasted-34.png)

```bash 重启使配置生效
systemctl restart mysqld && systemctl restart named-chroot
```

- **添加A记录**

![upload successful](/images/pasted-35.png)

![upload successful](/images/pasted-36.png)

- **添加反向解析**

![upload successful](/images/pasted-37.png)

- **反向解析添加完成后,查看状态为绿色即表示NamedManager DNS搭建成功**

![upload successful](/images/pasted-38.png)


###### 
