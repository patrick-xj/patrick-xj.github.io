title: jira-wiki 搭建
tags:
  - Linux-service
date: 2019-08-21 07:44:39
---
+ **Jira 和 Confluence 一起部署安装**
   - [Confluence](https://confluence.atlassian.com/doc/installing-confluence-on-linux-from-archive-file-255362363.html)
     - 信息可协同共享编辑、查看
     - 按空间分类分权,可阻隔跨部门能查看
   - [Jira](https://confluence.atlassian.com/adminjiraserver/installing-jira-applications-on-linux-from-archive-file-938846844.html)
     - 适用于开发团队协作问题追踪、跟进管理
     - 按项目分类分权,实现不同部门拥有各自独立项目或公共项目等
     - 自定义工作流,实现不同环节流程流转到指定不同用户或组执行下一步工作
 
###### 
 <!--more-->
 
1. **部署过程**
  - 安装包准备
  - JDK 配置
  - 数据库安装
  - Jira 安装及破解
  - Confluence 安装及破解并关联 Jira

###### 
 
2. 安装包准备

```bash Jira、Confluence 包下载
# CentOS 7系统
# 需先安装Jira,再安装Confluence。便于2个应用之间进行关联

# jira 下载 'atlassian-jira-software-8.2.1-x64.bin'
# 网页链接: https://confluence.atlassian.com/jirasoftwareserver/installing-jira-software-938845212.html
wget https://product-downloads.atlassian.com/software/jira/downloads/atlassian-jira-software-8.2.1-x64.bin

# confluence 下载 'atlassian-confluence-6.13.5-x64.bin'
wget https://product-downloads.atlassian.com/software/confluence/downloads/atlassian-confluence-6.13.5-x64.bin
```
```bash  MySQL 5.7 准备
wget https://repo.mysql.com//mysql80-community-release-el7-3.noarch.rpm
rpm -ivh mysql80-community-release-el7-3.noarch.rpm
sed -i '28c enabled=0' /etc/yum.repos.d/mysql-community.repo
sed -i '21c enabled=1' /etc/yum.repos.d/mysql-community.repo
yum clean all && yum repolist

# MySQL 连接工具下载
# 下载地址： https://dev.mysql.com/downloads/file/?id=480090
wget https://cdn.mysql.com//archives/mysql-connector-java-5.1/mysql-connector-java-5.1.47.tar.gz
```

###### 

3. **JDK 安装**

```bash
yum -y install java
```

###### 

4. **数据库安装配置**

```bash 数据库安装
yum -y install perl-Data-Dumper perl-JSON perl-Time-HiRes mysql-server dejavu-sans-fonts
systemctl start mysqld && systemctl enable mysqld
mysql -V
grep "password" /var/log/mysqld.log
mysql -uroot -p
mysql> set global validate_password_policy=0;
mysql> set global validate_password_length=6;
mysql> alter user user() identified by 'INadm.com';
mysql> set global tx_isolation='READ-COMMITTED';		# 必须使用'READ-COMMITTED'作为默认隔离级别
```

```bash 创建wiki、jira库并授权
# 创建jira 数据库
mysql> create database jiradb character set utf8 collate utf8_bin;
# 授权jira账号给jiradb数据库
mysql> grant all on jiradb.* to jira@'localhost' identified by 'jira.com';

# 创建confluence数据库
mysql> create database wikidb character set utf8 collate utf8_bin;
# 授权confluence<wiki>账号给wikidb数据库
mysql> grant all privileges on wikidb.* to wiki@'localhost' identified by 'wiki.com';
```

```bash 数据库永久配置
# vim /etc/my.cnf
[mysqld]
character-set-server=utf8				# 将默认字符集指定为UTF-8
collation-server=utf8_bin
default-storage-engine=INNODB				# 将默认存储引擎设置为InnoDB
max_allowed_packet=256M					# 指定值max_allowed_packet至少为256M
innodb_log_file_size=2GB				# 指定值  innodb_log_file_size 至少为2GB
transaction-isolation=READ-COMMITTED			# 确保数据库的全局事务隔离级别已设置为READ-COMMITTED
binlog_format=row					# 检查二进制日志记录格式是否配置为使用“基于行”的二进制日志记录

character-set-server=utf8 				# 将默认字符集指定为UTF-8
collation-server=utf8_bin 						
default-storage-engine=INNODB 				# 将默认存储引擎设置为InnoDB
max_allowed_packet=256M 				# 指定值max_allowed_packet至少为256M
innodb_log_file_size=2GB				# 指定值  innodb_log_file_size 至少为2GB
transaction-isolation=READ-COMMITTED 			# 确保数据库的全局事务隔离级别已设置为READ-COMMITTED
binlog_format=row 					# 检查二进制日志记录格式是否配置为使用“基于行”的二进制日志记录systemc
# systemctl restart mysqld
```

###### 

5. **Jira 安装**

```bash
# chmod +x atlassian-jira-software-8.2.1-x64.bin
# ./atlassian-jira-software-8.2.1-x64.bin
  o 							# ok;c 是取消
  2 							# 自定义设置
    [/opt/atlassian/jira]				# jira安装目录路径<可自定义;回车使用默认>
    [/var/atlassian/application-data/jira] 		# jira默认数据路径<可自定义;回车使用默认>
    修改jira端口 					# <可自定义;回车使用默认>
  y 							# 做为后台启动程序
  i 							# 开始安装
  n 							# 不启动
```

```bash 单独复制jira的mysql连接驱动
cp mysql-connector-java-5.1.47*.jar /opt/atlassian/jira/atlassian-jira/WEB-INF/lib/
/etc/init.d/jira start					 # 启动Jira
```

```bash web 浏览器配置
http://jira.inadm.com:8080
  1. 语言设置<中文>
  2. 我将设置它自己
  3. 数据库设置
    数据库类型: MySQL5.6(安装5.7选择5.6;5.7验证有异常,具体原因不详)
    主机: localhost
    端口: 3306
    数据库: jiradb
    用户名: jira
    密码: jira.com
    测试连接
    下一步
  4. 设置应用程序的属性
    模式: 私有
    下一步
  5. 请指定您的许可证关键字
    点击: 生成Jira试用许可证(需要有atlassian账号进行操作)
    product: Jira Software (Data Center)
    License type: Jira Software(Server)
    Organization: test
    Your instance is: up and running
    Server ID: B319-EQYT-0DEF-2P1U(输入服务器ID)
    Generate License
    贴入Key 下一步
  6. 设置管理员账号
    admin
    admin@inadm.com
    admin
    admin.com 	admin.com
    下一步
  7. 设置电子邮件通知
    以后再说
    完成
  8. Welcome to Jira, admin!
    中文
  9. 欢迎
    创建一个新项目
```

```bash Jira 破解
# 破解包下载请移步这位大神处: https://www.icode9.com/content-4-388552.html

/etc/init.d/jira stop
# 原文件移走
mv /opt/atlassian/jira/atlassian-jira/WEB-INF/atlassian-bundled-plugins/atlassian-universal-plugin-manager-plugin-4.0.2.jar /root
# 放入破解文件并修改为指定版本号 <破解包中>
cp atlassian-universal-plugin-manager-plugin-2.22.9.jar /opt/atlassian/jira/atlassian-jira/WEB-INF/atlassian-bundled-plugins/atlassian-universal-plugin-manager-plugin-4.0.2.jar
chmod 644 /opt/atlassian/jira/atlassian-jira/WEB-INF/atlassian-bundled-plugins/atlassian-universal-plugin-manager-plugin-4.0.2.jar
# 原文件移走
mv /opt/atlassian/jira/atlassian-jira/WEB-INF/lib/atlassian-extras-3.2.jar /root 
# 放入破解文件 <破解包中>
cp atlassian-extras-3.2.jar /opt/atlassian/jira/atlassian-jira/WEB-INF/lib/atlassian-extras-3.2.jar
chmod 644 /opt/atlassian/jira/atlassian-jira/WEB-INF/lib/atlassian-extras-3.2.jar
/etc/init.d/jira start
# 浏览器登录
  设置
  应用程序
  版本和许可证: 查看激活成功
```
![upload successful](/images/pasted-48.png)

###### 

6. **Confluence 安装**

```bash
# chmod +x atlassian-confluence-6.13.5-x64.bin
# ./atlassian-confluence-6.13.5-x64.bin
  o 							 # ok
  2							 # 自定义
    [/opt/atlassian/confluence]				 # 安装路径
    [/var/atlassian/application-data/confluence]	 # 数据路径
  1 							 # 推荐设置
  y 							 # 安装
  y 							 # 启动
```

```bash web 浏览器配置
http://jira.inadm.com:8090
  1. 语言设置
  2. 产品安装
  3. 获取应用: 直接下一步
  4. 授权码: BFWY-BXFZ-WR61-C20T
# /etc/init.d/confluence stop				 # 关闭 confluence
```

```bash wiki 破解
# 破解包下载到Windows本地: https://files.cnblogs.com/files/Javame/confluence%E7%A0%B4%E8%A7%A3%E5%B7%A5%E5%85%B7.zip

# 复制 atlassian-extras-decoder-v2-3.4.1.jar 使用破解工具修改此文件后还原到原目录
mv /opt/atlassian/confluence/confluence/WEB-INF/lib/atlassian-extras-decoder-v2-3.4.1.jar /root
# 修改为atlassian-extras-2.4.jar文件名
mv atlassian-extras-decoder-v2-3.4.1.jar atlassian-extras-2.4.jar
sz atlassian-extras-2.4.jar

# windows 操作破解
  1. 本地电脑安装 jre-8u221-windows-x64 工具
  2. confluence_keygen 右键打开方式选择Java打开
    Name: invisible 					# 可随意填写
    Email: invisible@scene.nl
    iNViSiBLE TEAM
    Server ID: BFWY-BXFZ-WR61-C20T 			# 记录的Server ID
    单击 .gen! 						# 生成key,保存记录
    单击 path! 						# 选择atlassian-extras-2.4.jar文件进行破解
# 将破解后的文件还原至原目录
cd /opt/
rz 														# 将破解包上传上来
mv atlassian-extras-2.4.jar atlassian-extras-decoder-v2-3.4.1.jar
cp atlassian-extras-decoder-v2-3.4.1.jar /opt/atlassian/confluence/confluence/WEB-INF/lib/

```
![upload successful](/images/pasted-49.png)

```bash 上传MySQL连接驱动
cp mysql-connector-java-5.1.47-bin.jar /opt/atlassian/confluence/confluence/WEB-INF/lib/

/etc/init.d/confluence start				# 启动confluence
```

```bash 回到 web 页面继续配置
  授权码: 输入得出来的Key,下一步
  设置您的数据库: 我自己得数据库
    数据库类型: MySQL
    安装类型: 简单
    主机名: 127.0.0.1
    端口: 3306
    数据库名称: wikidb
    用户名: wiki
    密码: wiki.com
    连接测试
  加载内容
    空白站点
  配置用户管理
    与Jira连接
      Jira基础URL： http://jira.inadm.com:8080/
      账号: admin
      密码: admin.com
      下一步
    从Jira中下载用户和组
      下一步
    设置成功
      开始
  查看授权信息
    一般配置
    授权细节
```
![upload successful](/images/pasted-50.png)

###### 

7. **启动服务配置**

```bash jira 启动服务配置
# cat > /usr/lib/systemd/system/jira.service << _EOF_
[Unit]
Description=Jira
After=network.target

[Service]
Type=forking
ExecStart=/etc/init.d/jira start
ExecReload=/etc/init.d/jira restart
ExecStop=/etc/init.d/jira stop

[Install]
WantedBy=multi-user.target
_EOF_
```

```bash confluence 启动服务配置
# cat > /usr/lib/systemd/system/confluence.service << _EOF_
[Unit]
Description=Confluence
After=network.target

[Service]
Type=forking
ExecStart=/etc/init.d/confluence start
ExecReload=/etc/init.d/confluence restart
ExecStop=/etc/init.d/confluence stop

[Install]
WantedBy=multi-user.target
_EOF_
```

```bash 使启停配置生效、开机自启
systemctl daemon-reload
systemctl enable jira && systemctl enable confluence
```

###### 
