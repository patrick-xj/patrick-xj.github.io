title: chfs 文件共享
tags:
  - Linux-service
date: 2019-10-30 00:48:44
---
+ **CuteHttpFileServer/chfs是一个免费的、HTTP协议的文件共享服务器，使用浏览器可以快速访问**

###### 
<!--more-->

+ **具有以下特点 [[官方网站](http://iscute.cn/chfs)]**
  - 单个文件，核心功能无需其他文件
  - 跨平台运行，支持主流平台：Windows，Linux和Mac
  - 界面简洁，简单易用
  - 支持扫码下载和手机端访问，手机与电脑之间共享文件非常方便
  - 支持账户权限控制和地址过滤
  - 支持快速分享文字片段
  - 支持webdav协议

###### 

+ **CHFS For Linux 安装**
```bash 安装准备及下载包文件
yum -y install unzip wget
mkdir -p chfs-linux /usr/local/chfs /data/{logs/chfs,chfs} /data/chfs/{files,images,scripts,packges}
    # chfs-linux 安装前准备文件目录
    # /data/chfs 程序目录; /data/logs/chfs 日志文件目录
    # /data/chfs/{files,images,scripts,packges} 共享目录
wget http://iscute.cn/tar/chfs/2.0/chfs-linux-amd64-2.0.zip			# 最新包文件
unzip chfs-linux-amd64-2.0.zip -d chfs-linux
chmod +x chfs-linux/chfs && mv chfs-linux/chfs /usr/local/chfs/
```

###### 

+ **CHFS 主配置文件**
  - **[参阅配置文档](https://github.com/fcwys/chfs-linux.git)**

```bash 
# cat > /usr/local/chfs/config.conf << _EOF_
port=80
path="/data/chfs/files|/data/chfs/images|/data/chfs/scripts|/data/chfs/packges"
allow=
log=/data/logs/chfs/
html.title=Web File Server
html.notice=内部资料,请勿传播!!!
image.preview=false
ssl.cert=
ssl.key=
folder.leaf.download=false
session.timeout=30
rule=::
rule=sa01:123456:RWD
rule=dev01:123456:RWD
_EOF_
```

###### 

+ **CHFS Service启动文件**
```bash 服务启动文件
# cat > /usr/lib/systemd/system/chfs.service << _EOF_
[Unit]
Description=CHFS Service
After=network.target

[Service]
Type=simple
User=root
Restart=always
RestartSec=5s
ExecStart=/usr/local/chfs/chfs --file=/usr/local/chfs/config.conf
TimeoutStopSec=0
KillSignal=SIGTERM
SendSIGKILL=no
SuccessExitStatus=0

[Install]
WantedBy=multi-user.target
_EOF_
```

###### 

+ **启服务,验证**
```bash
systemctl daemon-reload
systemctl start chfs && systemctl enable chfs
netstat -nlput|grep 80
```
http://ip_address
![upload successful](/images/pasted-0.png)
###### 
