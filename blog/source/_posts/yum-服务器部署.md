title: yum 服务器部署
tags:
  - Linux-service
date: 2019-12-08 21:15:02
---
+ **YUM 源服务器部署**
  - YUM 源服务器搭建
  - YUM 客户端repo
  
<font size=2>搭建IDC企业内网YUM源服务器。客户端无需在向外网获取安装包
本文仅介绍centos7源获取,其它系统获取方式基本类似</font>

###### 
<!--more-->

1.1 **YUM 服务端基础配置**

<font size=2></font>

```bash rpm包数据存储路径及相关包安装
# mkdir -p /data/www/repos/centos/{6,7,8}/{os,updates,extras,centosplus}/x86_64
# mkdir -p /data/www/repos/epel/{6,7,8}/x86_64
# chmod -R 755 /data/www/repos
# yum -y install rsync httpd createrepo
```

1.2 **YUM 获取centos官方包**
```bash 获取CentOS rpm官方包
// 同步centos官方包到本地
# rsync -avzP --delete --exclude='repodata' rsync://rsync.mirrors.ustc.edu.cn/centos/7/os/x86_64/ /data/www/repos/centos/7/os/x86_64/
# rsync -avzP --delete --exclude='repodata' rsync://rsync.mirrors.ustc.edu.cn/centos/7/updates/x86_64/ /data/www/repos/centos/7/updates/x86_64/
# rsync -avzP --delete --exclude='repodata' rsync://rsync.mirrors.ustc.edu.cn/centos/7/extras/x86_64/ /data/www/repos/centos/7/extras/x86_64/
# rsync -avzP --delete --exclude='repodata' rsync://rsync.mirrors.ustc.edu.cn/centos/7/centosplus/x86_64/ /data/www/repos/centos/7/centosplus/x86_64/
    -a          归档模式，表示以递归方式传输文件，并保持所有文件属性，等于-rlptgoD
    -v          详细模式输出
    -z          对备份的文件在传输时进行压缩处理
    --dalete    删除那些DST中SRC没有的文件
    --exclude   指定排除不需要传输的文件模式

// 同步epel包到本地
# rsync -avzP --delete --exclude='repodata' rsync://rsync.mirrors.ustc.edu.cn/epel/7/x86_64/ /data/www/repos/epel/7/x86_64
```
1.3 **创建rpm包仓库的库文件**
```bash 创建repodate数据库文件
// 客户端获取服务端数据,首先是通过数据库文件找到所需要的rpm包,然后库文件调出指定rpm包交给客户端
# createrepo /data/www/repos/centos/7/os/x86_64/
# createrepo /data/www/repos/centos/7/updates/x86_64/
# createrepo /data/www/repos/centos/7/extras/x86_64/
# createrepo /data/www/repos/centos/7/centosplus/x86_64/
# createrepo /data/www/repos/epel/7/x86_64/
```
1.4 **服务端定时更新官方rpm包源**
```bash 每天定期拉取脚本
# vim /etc/cron.daily/update-repo
#!/bin/bash
VER='7'
ARCH='x86_64'
REPOS=(os updates extras centosplus)
for REPO in ${REPOS[@]}; do
   rsync -avz --delete --exclude='repodata' \
   rsync://rsync.mirrors.ustc.edu.cn/centos/${VER}/${REPO}/${ARCH}/ /data/www/repos/centos/${VER}/${REPO}/${ARCH}/
   createrepo /data/www/repos/centos/${VER}/${REPO}/${ARCH}
done
rsync -avz --delete --exclude='repodata' rsync://rsync.mirrors.ustc.edu.cn/epel/${VER}/${ARCH}/ /data/www/repos/epel/${VER}/${ARCH}
createrepo /data/www/repos/centos/${VER}/${ARCH}

# chmod 755 /etc/cron.daily/update-repo
```
1.5 **NGINX 配置**
```bash nginx配置http走80端口
// 客户端通过http 80端口拉取数据
# yum -y install nginx
# vim /etc/nginx/conf/nginx.conf
...
server {
    listen       80;
    server_name  yum.inadm.com;

    location / {
        root /data/www;
        autoindex on;
        autoindex_localtime on;
        autoindex_exact_size off;
        charset utf-8,gbk;
    }
}
...

# systemctl start nginx && systemctl enable nginx
```

2.1 **YUM 客户端repo**
```bash
# mkdir -p /etc/yum.repos.d/bak
# mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak
// 将下面2个仓库文件放到/etc/yum.repos.d/目录下
```

```bash centos repo仓库文件
# cat /etc/yum.repos.d/CentOS-Base.repo
[base]
name=CentOS-$releasever - Base
baseurl=http://yum.inadm.com/repos/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[updates]
name=CentOS-$releasever - Updates
baseurl=http://yum.inadm.com/repos/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[extras]
name=CentOS-$releasever - Extras
baseurl=http://yum.inadm.com/repos/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[centosplus]
name=CentOS-$releasever - centosplus
baseurl=http://yum.inadm.com/repos/centos/$releasever/centosplus/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
```

```bash centos epel仓库文件
# cat /etc/yum.repos.d/epel.repo
[epel]
name=CentOS-$releasever - epel
baseurl=http://yum.inadm.com/repos/epel/$releasever/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
```

```bash 客户端获取服务端源缓存信息
# yum clean all && rm -rf /var/cache/yum/* && yum repolist
```

###### 
