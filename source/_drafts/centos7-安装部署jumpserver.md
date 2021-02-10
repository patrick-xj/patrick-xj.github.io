title: centos7 安装部署jumpserver
tags:
  - Linux-service
date: 2020-09-28 17:12:18
---
+ **Jumpserver 开源堡垒机搭建**
  - 实现开发、运维登陆内部服务器,方便管理

###### 
<!--more-->

+ **部署步骤**
  - 环境介绍
  - 安装部署
  - 跨区域分布式

#### 1. **环境介绍**
| 主机名 | IP地址 |
| ------ | ------ |
| jms01 | 172.16.10.80|
| client01 | 172.16.10.81 |

###### 


#### 2. **安装部署**

###### 2.1 基础包安装
```bash 包安装
# 阿里repo仓库
rm -f /etc/yum.repos.d/*
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
yum -y install epel-release

# 基础包安装
yum -y install vim wget gcc git

# jumpserver 依赖于redis
yum -y install redis
sed -i '480c requirepass pass' /etc/redis.conf
systemctl start redis && systemctl enable redis
```

###### 2.2 安装maridb数据库
```bash
yum -y install mariadb mariadb-devel mariadb-server MariaDB-shared
systemctl start mariadb && systemctl enable mariadb
mysql_secure_installation
Enter current password for root (enter for none):           # 无密码,直接回车
Set root password? [Y/n] Y
New password: 
Re-enter new password: 
mysql -uroot -ppass -A                                      # 用来登陆
MariaDB [(none)]> create database jumpserver default charset 'utf8';
```

###### 2.3 安装python 3,建立python虚拟环境
```bash python3.6安装
yum -y update python python-devel
yum -y install python36 python36-devel
```

```bash jumpserver 下载
wget https://github.com/jumpserver/jumpserver/archive/v2.1.0.tar.gz               # 源码 2.1.0
tar -xf v2.1.0.tar.gz 
mv jumpserver-2.1.0 /usr/local/jumpserver
yum -y install $(cat /usr/local/jumpserver/requirements/rpm_requirements.txt)
```

```bash 建立虚拟环境
cd /usr/local/
python3.6 -m venv py3                                                             # 创建虚拟环境
source /usr/local/py3/bin/activate                                                # 开启虚拟环境
pip install wheel -i https://mirrors.aliyun.com/pypi/simple/
pip install --upgrade pip setuptools -i https://mirrors.aliyun.com/pypi/simple/   # 升级pip
# 如安装报错缺乏依赖,直接手动pip install 依赖包。然后再重新执行此行命令直到完成安装
pip install -r /usr/local/jumpserver/requirements/requirements.txt -i https://mirrors.aliyun.com/pypi/simple/
```

```bash 更改Jumpserver配置
cd /usr/local/jumpserver
cp config_example.yml config.yml
SECRET_KEY=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 50)
echo "SECRET_KEY=$SECRET_KEY" >> ~/.bashrc
BOOTSTRAP_TOKEN=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)
echo "BOOTSTRAP_TOKEN=$BOOTSTRAP_TOKEN" >> ~/.bashrc
cat ~/.bashrc
    # SECRET_KEY=YaOIm1WxJqriaY8ir3WExkQA3b77E869Am4c6nChB37d65LTQ8
    # BOOTSTRAP_TOKEN=6Un1VIwaP5CZPVmp

# vim config.yml
4 SECRET_KEY: YaOIm1WxJqriaY8ir3WExkQA3b77E869Am4c6nChB37d65LTQ8
8 BOOTSTRAP_TOKEN: 6Un1VIwaP5CZPVmp
12 DEBUG: false
16 LOG_LEVEL: ERROR
22 SESSION_EXPIRE_AT_BROWSER_CLOSE: true
37 DB_USER: root
38 DB_PASSWORD: pass
52 REDIS_PASSWORD: pass
```

```bash 启动Jumpserver
# ./jms start -d
# ./jms start | stop | status | all
```

###### 2.4 coco jms_guacamole安装
```bash 安装docker环境
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum -y install docker-ce
systemctl enable docker
mkdir -p /etc/docker
wget -O /etc/docker/daemon.json http://demo.jumpserver.org/download/docker/daemon.json
systemctl restart docker
```
```bash 运行coco和jms_guacamole
docker run --name jms_koko -d -p 2222:2222 -p 127.0.0.1:5000:5000 -e CORE_HOST=http://172.16.10.80:8080 -e BOOTSTRAP_TOKEN=$BOOTSTRAP_TOKEN -e LOG_LEVEL=ERROR --restart=always jumpserver/jms_koko:2.1.0
docker run --name jms_guacamole -d -p 127.0.0.1:8081:8080 -e JUMPSERVER_SERVER=http://172.16.10.80:8080 -e BOOTSTRAP_TOKEN=$BOOTSTRAP_TOKEN -e GUACAMOLE_LOG_LEVEL=ERROR --restart=always jumpserver/jms_guacamole:2.1.0
docker ps
```

###### 2.5 Jumpserver前端安装
```bash
cd /usr/local/
wget https://demo.jumpserver.org/download/luna/v2.1.0/luna-v2.1.0.tar.gz
tar -xf luna-v2.1.0.tar.gz
mv luna-v2.1.0 luna
chown -R root:root luna

wget https://demo.jumpserver.org/download/lina/v2.1.0/lina-v2.1.0.tar.gz
tar -xf lina-v2.1.0.tar.gz 
mv lina-v2.1.0 lina
chown -R root.root lina
```
```bash nginx配置
yum -y install nginx
systemctl enable nginx
mkdir -p /etc/nginx/conf.d/vweb/
# vim /etc/nginx/nginx.conf
 36     #include /etc/nginx/conf.d/*.conf;
 37     include /etc/nginx/conf.d/vweb/*.conf;
# 注释掉server段

// jumpserver nginx 2.1.0 配置文件: https://demo.jumpserver.org/download/nginx/conf.d/2.1.0/
# vim /etc/nginx/conf.d/vweb/jumpserver.conf
server {
    listen 80;
    #server_name _;

    server_tokens off;
    ssl_protocols TLSv1.2;
 
    client_max_body_size 100m;
 
    location /ui/ {
        try_files $uri / /index.html;
        alias /usr/local/lina/;
        expires 24h;
    }
 
    location /luna/ {
        try_files $uri / /index.html;
        alias /usr/local/luna/;
        expires 24h;
    }
 
    location /media/ {
        add_header Content-Encoding gzip;
        root /usr/local/jumpserver/data/;
    }
 
    location /static/ {
        root /usr/local/jumpserver/data/;
        expires 24h;
    }
 
    location /koko/ {
        proxy_pass       http://localhost:5000;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_request_buffering off;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        #access_log off;
    }
 
    location /guacamole/ {
        proxy_pass       http://localhost:8081/;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_request_buffering off;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $http_connection;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        #access_log off;
    }
 
    location /ws/ {
    proxy_pass http://localhost:8070;
    proxy_buffering off;
        proxy_http_version 1.1;
    proxy_request_buffering off;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
 
    location /api/ {
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_pass http://localhost:8080;
    }
 
    location /core/ {
    proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_pass http://localhost:8080;
    }
 
    location / {
        rewrite ^/(.*)$ /ui/$1 last;
    }
}

# systemctl restart nginx
```

#### 3. **web配置**

###### 3.1 web页面配置
```bash 登陆web
http://172.16.10.80
默认用户名密码: admin:admin
```
配置管理用户
```base
ssh-keygan -t rsa
sz /root/.ssh/id_rsa
```
![upload successful](/images/pasted-60.png)
###### 

添加资产
```bash 下发秘钥
ssh-copy-id 172.16.10.80
ssh-copy-id 172.16.10.81
```
![upload successful](/images/pasted-62.png)
###### 

添加系统用户
![upload successful](/images/pasted-63.png)
###### 

资产授权
![upload successful](/images/pasted-64.png)
###### 

待优化更新 ....... 