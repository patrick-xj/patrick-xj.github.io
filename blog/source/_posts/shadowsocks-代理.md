title: shadowsocks 代理
tags:
  - Linux-service
date: 2019-08-09 08:36:08
---
+ **Centos 7 安装shadowsocks代理**
  - 三种模式: 
    - 全局模式: 所有流量全走代理
    - PAC自动模式: 自动根据PAC文件匹配则走代理,非自定义PAC文件的规则
    - PAC模式: 根据自身需求根据特定格式自定义IP或域名,匹配则走代理
  - 单用户与多用户
  - 客户端

###### 
<!--more-->

+ **shadowsocks 客户端设置三种模式,流量请求图**
![upload successful](/images/pasted-74.png)

+ **PAC文件规则模板**
||       2个竖杠表示匹配规则
@@||     竖杠后面2个at表示绕过规则

  - Windows
  Windows"编辑GFWList的用户规则"(user-rule)保存后默认会直接将编辑规则保存到pac文件
![upload successful](/images/pasted-77.png)
  
  
  - Mac OS
  Mac OS配置好PAC自定义规则后还需单击"从GFW List更新PAC"并关闭再开启shadowsocks则生效
![upload successful](/images/pasted-75.png)
![upload successful](/images/pasted-76.png)
  

1. 安装pip
```bash
curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
python get-pip.py
# 云主机报错,可跳过python安装,直接解决pip安装问题
```

2. 安装shadowsocks
```bash
pip install --upgrade pip
pip install shadowsocks
```

3. 单用户和多用户配置方式[1|2]
  - method加密方式: 服务端指定什么加密方式,客户端选择同样加密方式
```bash 单用户[1]
# vim /etc/shadowsocks.json
{
  "server": "0.0.0.0",
  "server_port": 8443,
  "password": "you_password",
  "method": "aes-256-cfb"
}
```
```bash 多用户[2]
# vim /etc/shadowsocks.json
{
  "server": "0.0.0.0",
  "local_address": "127.0.0.1",
  "local_port": 8443,
  "port_password":{
    "port_1":"you_password_1",
    "port_":"you_password_2",
    "port_":"you_password_3"
  },
  "timeout":600,
  "method":"aes-256-cfb",
  "fast_open": false
}
```

4. 启动设置
```bash
# cat /etc/systemd/system/shadowsocks.service
[Unit]
Description=Shadowsocks

[Service]
TimeoutStartSec=0
ExecStart=/usr/bin/ssserver -c /etc/shadowsocks.json

[Install]
WantedBy=multi-user.target

# systemctl enable shadowsocks
# systemctl start shadowsocks
# systemctl status shadowsocks -l
```

###### 

5.  [**客户端各平台软件**](https://shadowsockshelp.github.io/Shadowsocks/download.html)
  - Windows [教程](https://shadowsockshelp.github.io/Shadowsocks/windows.html)
  - Mac OS [教程](https://shadowsockshelp.github.io/Shadowsocks/mac.html)
  - Linux [教程](https://shadowsockshelp.github.io/Shadowsocks/linux.html)
  - Android [教程](https://shadowsockshelp.github.io/Shadowsocks/Android.html)
  - iPhone、iPad [教程](https://shadowsockshelp.github.io/Shadowsocks/ios.html)
  - [Chrome 浏览器教程](https://shadowsockshelp.github.io/Shadowsocks/Chrome.html)
  - [Firefox 浏览器教程](https://shadowsockshelp.github.io/Shadowsocks/Firefox.html)

* iPhone、iPad需要非大陆ID账号并且出口IP在非大陆区域才可搜索并下载 [Shadowrocket](https://shadowsockshelp.github.io/ios/)


###### 
