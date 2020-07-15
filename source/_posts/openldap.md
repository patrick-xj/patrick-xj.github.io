title: openldap 搭建
tags:
  - Linux-service
date: 2019-08-15 07:43:09
---
+ **OpenLDAP 统一管理用户认证应用系统**
  - 可实现一个账号密码登陆各应用系统
  - 方便用户使用,方便运维维护管理

###### 
<!--more-->

+ **OpenLDAP 部署**
  - YUM 安装
  - Server 初始化配置及构建组织架构
  - 客户端配置
  - LDAP 日志
  - OpenLDAP 客户端管理命令
  - OpenLDAP 图形化管理
  - sudo实现对OpenLDAP用户进行权限控制

###### 

1.1 **Yum 安装**

```bash Yum 方式安装OpenLDAP
yum -y install epel-release
yum -y install openldap compat-openldap openldap-clients openldap-servers openldap-servers-sql openldap-devel migrationtools
```

```bash 数据库文件配置
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG	# 复制DB_CONFIG至/var/lib/ldap
chown -R ldap.ldap /var/lib/ldap											# 赋权
chmod -R 700 /var/lib/ldap
systemctl start slapd.service && systemctl enable slapd.service
# /var/lib/ldap就是BerkeleyDB数据库默认存储的路径
systemctl status slapd
netstat -nlput|grep 389					# 默认明文端口389;密文端口636
```

###### 

2. **Server 初始化配置及构建组织架构**
  - cn=config 语法介绍
  - 设置 OpenLDAP server 管理员密码
  - 导入 schema ldif文件
  - 开启 memberOf
  - 设置域名
  - 设置组织架构
  - 添加用户

2.1 **cn=config 语法介绍**
```bash
# cn=config语法介绍
ldapadd -Y EXTERNAL -H ldapi://				# API方式操作
指定dn:
    changetype: modify					# 更改类型,一般都是modify [modify分为三种]
    	add						# 添加
    	delete						# 删除
    	replace						# 替换
    olcRootPW: xxxx					# 相关属性(key),后面跟相关密码字段
    objectClass: 
```

###### 

2.2 **设置slapdpasswd密码**

```bash LDAP 服务端管理密码
slappasswd -s INadm@123 > pass.txt
    # {SSHA}doo+tnMnu+blLotn8hVJbUJsu5/ov0MH		# 加密字符串密码
```
```bash
// 修改'olcDatabase={0}config.ldif'配置文件。导入pass.txt加密字符串密码
# cd /etc/openldap/slapd.d/cn=config
# mkdir -p /data/application/openldap/ldif
# cat /data/application/openldap/ldif/slappasswd.ldif
dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcRootPW
olcRootPW: {SSHA}doo+tnMnu+blLotn8hVJbUJsu5/ov0MH
# ldapadd -Y EXTERNAL -H ldapi:/// -f /data/application/openldap/ldif/slappasswd.ldif
```
![upload successful](/images/pasted-13.png)

###### 

2.3 **导入schema ldif文件**

```bash
# /etc/openldap/schema/每个ldif文件都有各自不同的用户,可根据需求配置
ls /etc/openldap/schema/							# YUM安装默认的schema文件在此路径,每一个schema都有一个对应的.ldif文件
cd /etc/openldap/slapd.d/cn=config/cn=schema
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif		# 账号管理工具
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif	# 添加用户基本属性,都来自于此文件
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/dyngroup.ldif		# 组/sudo
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/ppolicy.ldif 		# 做密码策略时用到的文件
```
![upload successful](/images/pasted-14.png)

2.4 **开启 memberOf**
  - 用途,加快用户/组查询速度

```bash
# cat /data/application/openldap/ldif/onModule.ldif
dn: cn=module,cn=config
objectClass: olcModuleList
cn: module

dn: cn=module{0},cn=config
changetype: modify
add: olcModulePath
olcModulePath: /usr/lib64/openldap/
# ldapadd -Y EXTERNAL -H ldapi:/// -f /data/application/openldap/ldif/onModule.ldif
```
```bash
# cat /data/application/openldap/ldif/memberOf.ldif
dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: memberof

dn: olcOverlay={0}memberof,olcDatabase={2}hdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcMemberOf
olcOverlay: {0}memberof
olcMemberOfDangling: ignore
olcMemberOfRefInt: TRUE
olcMemberOfGroupOC: groupOfUniqueNames
olcMemberOfMemberAD: uniqueMember
olcMemberOfMemberOfAD: memberOf
# ldapadd -Y EXTERNAL -H ldapi:/// -f /data/application/openldap/ldif/memberOf.ldif
```
```bash
# cat /data/application/openldap/ldif/refint.ldif
dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: refint

dn: olcOverlay={1}refint,olcDatabase={2}hdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcRefintConfig
olcOverlay: {1}refint
olcRefintAttribute: owner
olcRefintAttribute: manager
olcRefintAttribute: uniqueMember
olcRefintAttribute: member
olcRefintAttribute: memberOf
# ldapadd -Y EXTERNAL -H ldapi:/// -f /data/application/openldap/ldif/refint.ldif
```
![upload successful](/images/pasted-17.png)

![upload successful](/images/pasted-16.png)

![upload successful](/images/pasted-15.png)

###### 

2.5 **域名设置**

![upload successful](/images/pasted-18.png)

```bash
# cd /etc/openldap/slapd.d/cn=config
# cat /data/application/openldap/ldif/chdomain.ldif
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth"
  read by dn.base="cn=Manager,dc=inadm,dc=com" read by * none

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=inadm,dc=com

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=Manager,dc=inadm,dc=com

dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcRootPW
olcRootPW: {SSHA}doo+tnMnu+blLotn8hVJbUJsu5/ov0MH		# 服务端管理密码

dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {0}to attrs=userPassword,shadowLastChange by
  dn="cn=Manager,dc=inadm,dc=com" write by anonymous auth by self write by * none
olcAccess: {1}to dn.base="" by * read
olcAccess: {2}to * by dn="cn=Manager,dc=inadm,dc=com" write by * read
# ldapmodify -Y EXTERNAL -H ldapi:/// -f /data/application/openldap/ldif/chdomain.ldif 
    # 第一行: 替换监控文件里面的域名信息
    # 第二行: 更改Suffix
    # 第三行: 更改RootDN
    # 第四行: 增加密码
    # 第五行: 允许openldap用户自己修改密码

# 共修改了2个配置文件,此配置文件不能直接修改
    olcDatabase={1}monitor.ldif
    olcDatabase={2}hdb.ldif
```
![upload successful](/images/pasted-19.png)

###### 

2.6 **设置组织架构**

```bash
# 创建1个inadm
# 创建2个ou: People/Group
# 创建1个cn: Manager
# ou基础上创建一个组Host组

# cat /data/application/openldap/ldif/base.ldif
dn: dc=inadm,dc=com
objectClass: dcObject
objectClass: organization
dc: inadm
o: inadm.com

dn: ou=People,dc=inadm,dc=com
objectClass: organizationalUnit
objectClass: top
ou: People

dn: ou=Group,dc=inadm,dc=com
objectClass: organizationalUnit
ou: Group

dn: cn=Manager,dc=inadm,dc=com
objectClass: organizationalRole
cn: Manager

dn: cn=Host,ou=Group,dc=inadm,dc=com
objectClass: posixGroup
cn: Host
gidNumber: 1010
# ldapadd -x -D "cn=Manager,dc=inadm,dc=com" -w "INadm@123" -f /data/application/openldap/ldif/base.ldif
```

2.7 **添加用户**
```bash
# cat /data/application/openldap/ldif/adduser.ldif
dn: uid=patrick,ou=People,dc=inadm,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
homeDirectory: /home/patrick
userPassword: {SSHA}eHQQU+s4SgvJ8GE2+gB1YQT9riRw6H2v
loginShell: /bin/bash
cn: patrick
uidNumber: 1000
gidNumber: 1010
sn: sa admin
mail: patick@inadm.com
postalAddress: Shenzhen
mobile: 13388888888
# ldapadd -x -w "INadm@123" -D "cn=Manager,dc=inadm,dc=com" -f /data/application/openldap/ldif/adduser.ldif
```

###### 

3.1 客户端配置

```bash 备份还原客户端配置
authconfig --savebackup=openldap.bak        			# 备份
authconfig --restorebackup=openldap.bak     			# 还原
```

```bash 适用于centos 6/7
yum -y install nss-pam-ldapd authconfig				# 依赖包

authconfig --enableldap --enableldapauth --ldapserver=ldap://172.16.10.60 --disableldaptls --enablemkhomedir --ldapbasedn="dc=inadm,dc=com" --update
    --enableldap        用户信息启用ldap
    --enableldapauth	启用ldap进行身份验证
    --ldapserver        ldap server
    --disableldaptls    关闭加密处理;因为没使用加密方式
    --enablemkhomedir   创建家目录
    --ldapbasedn	ldap默认dn

getent shadow patrick           				# 查看是否能获取到 ldap user 密码
getent passwd patrick           				# 查看获取ldap user bash
```

4.1 **OpenLDAP 日志** [日志级别介绍](https://www.openldap.org/doc/admin24/slapdconf2.html)

```bash 日志级别查询
slapd -d ?             			 # 命令查看日志级别
```
![upload successful](/images/pasted-20.png)

```bash OpenLDAP 日志配置
# cat /data/application/openldap/ldif/setlog.ldif
dn: cn=config
changetype: modify
add: olcLogLevel
olcLoglevel: 256
# ldapmodify -Y EXTERNAL -H ldapi:/// -f /data/application/openldap/ldif/setlog.ldif
# systemctl restart slapd
```
```bash 日志切割
# cat /etc/logrotate.d/openldap
/data/logs/openldap/ldap.log {
    prerotate
        /usr/bin/chattr -a /data/logs/openldap/ldap.log
    endscript
    compress
    delaycompress
    notifempty
    rotate 100
    size 50M
    postrotate
        /usr/bin/chattr +a /data/logs/openldap/ldap.log
    endscript
}
```
```bash 定义日志文件位置
mkdir -p /data/logs/openldap
sed -i "74i local4.*                                                /data/logs/openldap/ldap.log" /etc/rsyslog.conf
systemctl restart rsyslog && systemctl restart slapd	# 日志文件已生成
```

###### 

4.1 **OpenLDAP 客户端管理命令**
  
 - **客户端管理命令 增、删、改、查**
  - ldapadd				添加user/ou
  - ldapdelete			删除user/ou
  - ldapmodify			修改用户字段信息
  - ldapmodrdn			修改uid信息
  - ldappasswd			修改user密码
  - ldapsearch			查询

```bash 添加用户
ldapadd
  -x				# 简单的认证
  -W				# 交互式输入密码
  -w				# 非交互式;后面直接跟password
  -H				# ldapuri，ldapapi的方式修改或者添加操作
  -h				# 后面跟ip地址,或者主机名
  -D				# "cn=Manager,dc=ojtest,dc=com"
  -v				# 显示详细结果
  -f				# FILENAME.ldif
  -a				# 新增条目
  -p				# 后面跟端口(明文:389)、(密文:636)
  -P				# 版本
ldapadd -x -w "INadm@123" -D "cn=Manager,dc=inadm,dc=com" -h172.16.10.60 -f /data/appliation/openldap/ldif/adduser.ldif
```
```bash 添加ou
// ldif 方式添加
# cat /data/appliation/openldap/ldif/addou.ldif
dn: ou=Users,dc=inadm,dc=com
objectClass: organizationalUnit
ou: Users
# ldapadd -x -D "cn=Manager,dc=inadm,dc=com" -w "INadm@123" -h172.16.10.60 -f /data/appliation/openldap/ldif/addou.ldif
```
```bash 删除用户
ldapdelete
  -x				# 简单的认证
  -W				# 交互式输入密码
  -w				# 非交互式;后面直接跟password
  -H				# ldapuri，ldapapi的方式修改或者添加操作
  -h				# 后面跟ip地址,或者主机名
  -D				# "cn=Manager,dc=ojtest,dc=com"
  -v				# 显示详细结果
  -f				# FILENAME.ldif
  -a				# 新增条目
  -p				# 后面跟端口(明文:389)、(密文:636)
  -P				# 版本

// 命令删除用户方式1
ldapdelete -x -D "cn=Manager,dc=inadm,dc=com" -w "INadm@123" -h172.16.10.60 "uid=test01,ou=People,dc=inadm,dc=com"

// 命令删除用户方式2
# cat /data/appliation/openldap/ldif/deluser.ldif
uid=test01,ou=People,dc=inadm,dc=com
# ldapdelete -x -D "cn=Manager,dc=inadm,dc=com" -w "INadm@123" -h172.16.10.60 -f /data/appliation/openldap/ldif/deluser.ldif
```
```bash 删除ou
// 删除ou命令方式1
# ldapdelete -x -D "cn=Manager,dc=inadm,dc=com" -w "INadm@123" -h172.16.10.60 "ou=Users,dc=inadm,dc=com"

// ldif 方式删除
# cat /data/appliation/openldap/ldif/delou.ldif 
ou=Users,dc=inadm,dc=com
# ldapdelete -x -D "cn=Manager,dc=inadm,dc=com" -w "INadm@123" -h172.16.10.60 -f /data/appliation/openldap/ldif/delou.ldif
```
```bash ldapmodify 修改用户条目
ldapmodify
  cn=config
    changtype: add/delete/replace
      # add		添加
      # delete		删除
      # replace		修改

# 将用户的/bin/bash修改为/sbin/nologin
# cat /data/appliation/openldap/ldif/modifyuser.ldif
dn: uid=test01,ou=People,dc=inadm,dc=com
changetype: modify
replace: loginShell
loginShell: /sbin/nologin
# ldapmodify -x -D "cn=Manager,dc=inadm,dc=com" -w "INadm@123" -h172.16.10.60 -f /data/appliation/openldap/ldif/modifyuser.ldif
```
```bash ldapmodrdn 修改rdn --- 删除原有uid
# 将用户test02修改为test20;uid变化
# cat /data/appliation/openldap/ldif/chrdnuser.ldif
dn: uid=test02,ou=People,dc=inadm,dc=com
changetype: modrdn
newrdn: uid=test20								# 修改为test20
deleteoldrdn: 1									# 将原来的test02删除
# ldapmodify -x -D "cn=Manager,dc=inadm,dc=com" -w "INadm@123" -h172.16.10.60 -f /data/appliation/openldap/ldif/chrdnuser.ldif
```
```bash 修改rdn --- 不删除原有uid
# 将用户test03修改为test30
ldapmodrdn -x -D "cn=Manager,dc=inadm,dc=com" -w "INadm@123" -h172.16.10.60 "uid=test03,ou=People,dc=inadm,dc=com" "uid=test30"
    # "uid=test03,ou=People,dc=inadm,dc=com"					# 默认是test10
    # "uid=test11"								# 修改为test30
    # -r				# 如果修改uid后,使用rdn方式需要删除原有uid,则使用-r选项
```
```bash ldappasswd 修改用户密码
ldappasswd
    -s					# 指定新的密码,明文方式可以histroy查看到
    -S					# 指定新的密码,需手动输入密码,比较安全
ldappasswd -x -D "cn=Manager,dc=inadm,dc=com" -w "INadm@123" -h172.16.10.60 "uid=test01,ou=People,dc=inadm,dc=com" -s "Aa123456"
ldappasswd -x -D "cn=Manager,dc=inadm,dc=com" -w "INadm@123" -h172.16.10.60 "uid=test01,ou=People,dc=inadm,dc=com" -S

# 不指定任何密码修改选项,自动生成新的密码
ldappasswd -x -D "cn=Manager,dc=inadm,dc=com" -w "INadm@123" -h172.16.10.60 "uid=test01,ou=People,dc=inadm,dc=com"

# 根据旧密码产生新的密码
ldappasswd -x -D "cn=Manager,dc=inadm,dc=com" -w "INadm@123" -h172.16.10.60 "uid=test01,ou=People,dc=inadm,dc=com" -a iLRMte54
```
```bash 查询
ldapsearch -x -LLL uid			# 查看所有uid条目
ldapsearch -x -LLL uid=patrick		# 查看某一个用户的uid,则仅显示此uid的详细信息
ldapsearch -x -LLL uid=patrick +	# 显示此用户的隐藏属性
```

###### 

5. **OpenLDAP 图形化管理**

5.1 **[windows绿色小工具](http://www.ldapadmin.org/)**
![upload successful](/images/pasted-21.png)

5.2 **[Mac OS 管理工具 ApacheDirectoryStudio](directory.apache.org/studio)**
![upload successful](/images/pasted-24.png)

![upload successful](/images/pasted-25.png)


6. **sudo实现对OpenLDAP用户进行权限控制**

  - 系统sudo实现方式
  - OpenLDAP Server 实现sudo方式

6.1 **系统sudo实现方式**
```bash 配置仅test01用户有权限删除用户
sed -i '21i User_Alias      LDAP= test01,test02' /etc/sudoers
sed -i '22i User_Alias      LDAP01= test01' /etc/sudoers
sed -i '23i LDAP    ALL=(ALL)       NOPASSWD: /bin/more,/sbin/useradd,/usr/bin/passwd' /etc/sudoers
sed -i '24i LDAP01  ALL=(ALL)       NOPASSWD: /bin/more,/sbin/useradd,/usr/bin/passwd,/usr/sbin/userdel' /etc/sudoers
```

6.2 **OpenLDAP Server 实现sudo方式**

```bash
# openldap没有sudo.schema,需通过模板ldif文件导入sudo模块
// server
    1. sudo.schema --> /etc/openldap/schema
    2. 导入ldif文件
    3. 定义sudo权限列表
    4. 创建条目
// client
    1. openldap user --> system_os -> sudo -> openldapserver
```
```bash Server端获取schema.OpenLDAP文件
# rpm -ql `rpm -qa sudo`|grep schema.OpenLDAP
/usr/share/doc/sudo-1.8.19p2/schema.OpenLDAP
# cp /usr/share/doc/sudo-1.8.19p2/schema.OpenLDAP /etc/openldap/schema/sudo.schema
```
```bash 生成ldif文件
echo "include /etc/openldap/schema/sudo.schema" > /tmp/sudo.conf
# 生成sudo的ldif文件
slapcat -f /tmp/sudo.conf -F /tmp/ -n0 -s "cn={0}sudo,cn=schema,cn=config" > /tmp/sudo.ldif	
# 删除sudo.ldif文件末尾的8行时间戳
head -n-8 /tmp/sudo.ldif > /data/application/openldap/ldif/sudo.ldif
sed -i 's/{0}sudo/{12}sudo/g' /data/application/openldap/ldif/sudo.ldif		# 将{0}sudo修改避免冲突
ldapadd -Y EXTERNAL -H ldapi:/// -f /data/application/openldap/ldif/sudo.ldif	# 通过api方式导入
ll /etc/openldap/slapd.d/cn=config/cn=schema					# 查看导入的schema文件
```
![upload successful](/images/pasted-26.png)

6.3 **定义用户的默认权限**

```bash 创建每一个用户的默认权限
# cat /data/application/openldap/ldif/setdefuser.ldif
dn: ou=sudoers,dc=inadm,dc=com
objectClass: organizationalUnit
ou: sudoers

dn: cn=defaults,ou=sudoers,dc=inadm,dc=com
objectClass: sudoRole
cn: defaults
description: Default sudoOption’s go here
sudoOption: requiretty
sudoOption: !visiblepw
sudoOption: always_set_home
sudoOption: env_reset
sudoOption: env_keep="COLORS DISPLAY HOSTNAME HISTSIZE INPUTRC KDEDIR LS_COLORS"
sudoOption: env_keep+="MAIL PS1 PS2 QTDIR USERNAME LANG LC_ADDRESS LC_CTYPE"
sudoOption: env_keep+="LC_COLLATE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES"
sudoOption: env_keep+="LC_TIME LC_ALL LANGUAGE LINGUAS _XKB_CHARSET XAUTHORITY"
sudoOption: secure_path=/sbin:/bin:/usr/sbin:/usr/bin

dn: cn=%sa,ou=sudoers,dc=inadm,dc=com
objectClass: sudoRole
cn: %sa
sudoUser: %sa
sudoHost: ALL
sudoOption: !authenticate
sudoCommand: /bin/bash

dn: cn=%dev,ou=sudoers,dc=inadm,dc=com
objectClass: sudoRole
cn: %dev
sudoUser: %dev
sudoHost: ALL
sudoOption: authenticate
sudoCommand: /usr/bin/*
# ldapadd -D "cn=Manager,dc=inadm,dc=com" -h172.16.10.60 -x -w "INadm@123" -f /data/application/openldap/ldif/setdefuser.ldif
```
```bash 创建组
# cat /data/application/openldap/ldif/addgroup.ldif
dn: cn=sa,ou=Group,dc=inadm,dc=com
objectClass: posixGroup
cn: sa
gidNumber: 10001

dn: cn=dev,ou=Group,dc=inadm,dc=com
objectClass: posixGroup
cn: dev
gidNumber: 10002
# ldapadd -x -D "cn=Manager,dc=inadm,dc=com" -w "INadm@123" -f /data/application/openldap/ldif/addgroup.ldif
```
```bash 创建用户

dn: uid=sa01,ou=People,dc=inadm,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
homeDirectory: /home/sa01
userPassword: {SSHA}eHQQU+s4SgvJ8GE2+gB1YQT9riRw6H2v
loginShell: /bin/bash
cn: sa01
uidNumber: 1001
gidNumber: 10001
sn: sa01
mail: sa01@inadm.com
postalAddress: Shenzhen
mobile: 13388888888

dn: uid=dev01,ou=People,dc=inadm,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
homeDirectory: /home/dev01
userPassword: {SSHA}eHQQU+s4SgvJ8GE2+gB1YQT9riRw6H2v
loginShell: /bin/bash
cn: dev01
uidNumber: 1002
gidNumber: 10002
sn: dev01
mail: dev01@inadm.com
postalAddress: Shenzhen
mobile: 13388888888
# ldapadd -x -D "cn=Manager,dc=inadm,dc=com" -w "INadm@123" -f /data/application/openldap/ldif/adduser.ldif
```

6.4 **Linux Client 修改配置连接到 OpenLDAP**

```bash
# vim /etc/sudo-ldap.conf							# 配置后client即可找到openldap server
    87 URI             ldap://172.16.10.60
    88 BASE            dc=inadm,dc=com
    89 sudoers_base  ou=sudoers,dc=inadm,dc=com
# vim /etc/nsswitch.conf
    33 passwd:     files ldap
    34 shadow:     files ldap
    35 group:      files ldap
    ...
    64 sudoers:    ldap files
# systemctl restart nslcd
# id dev01						# 验证连接是否成功
# 以上配置基于客户端的sudo
# sa01有sudo权限;dev01无sudo权限
```

###### 







