title: zimbra 邮箱部署
tags:
  - Linux-service
date: 2019-08-10 05:08:20
---
+ **开源版 zimbra 邮箱部署**
  - zimbra 安装前准备
  - zimbra 单机安装
  - HTTPS 配置
  - 白名单设置
  - 阿里ecs申请放行25端口

###### 
<!--more-->

1. **zimbra 安装前准备**

```bash 系统环境准备
systemctl stop iptables						# 部署前建议先关闭防火墙以免影响部署顺利执行
systemctl stop postfix && systemctl disable postfix		# 关闭系统自带e-mail

# DNS配置
echo -e "Wan_IP    	 DomianName.com Mail.DomianName.com" >> /etc/hosts
sed -i '1i nameserver 127.0.0.1' /etc/resolv.conf

hostnamectl set-hostname Top_DomianName.com
reboot
```
```bash 解析配置
MX	10	@		TOP_DOMAIN.COM
A		@		WAN_IP				# 配置反解析
A		MAIL		WAN_IP

# dig Top_DomianName.com MX +short          			# 检查MX解析是否生效和正常
```

###### 

2. **zimbra 安装**

```bash 下载包
# Zimbra Collaboration 8.7开始，Zimbra依赖于自己的存储库打包系统，这意味着Zimbra安装脚本会自动处理操作系统的依赖关系
# /opt目录建议空间准备足够
wget https://files.zimbra.com/downloads/8.8.15_GA/zcs-8.8.15_GA_3869.RHEL7_64.20190918004220.tgz
tar -xf zcs-8.8.15_GA_3869.RHEL7_64.20190918004220.tgz -C /opt
```
```bash 安装
# zimbra默认打包redhat。centos必须加--platform-override
./install.sh --platform-override
  Do you agree with the terms of the software license agreement? [N] Y
  Use Zimbra's package repository [Y] Y
  Install zimbra-ldap [Y] Y
  Install zimbra-logger [Y] Y
  Install zimbra-mta [Y] Y
  Install zimbra-dnscache [Y] Y
  Install zimbra-snmp [Y] Y
  Install zimbra-store [Y] Y
  Install zimbra-apache [Y] Y
  Install zimbra-spell [Y] Y
  Install zimbra-memcached [Y] Y
  Install zimbra-proxy [Y] Y
  Install zimbra-drive [Y] Y
  Install zimbra-imapd (BETA - for evaluation only) [N] Y 
  Install zimbra-chat [Y] N
  The system will be modified.  Continue? [N] Y
  Change domain name? [Yes] N
Address unconfigured (**) items  (? - help) 7
Select, or 'r' for previous menu [r] 4
Password for admin@inadc.com (min 6 characters): [LnHQBqtsW] MoPTeqJkB
Select, or 'r' for previous menu [r]
Select from menu, or press 'a' to apply config (? - help) a
Save configuration data to a file? [Yes] Yes
Save config in file: [/opt/zimbra/config.7723] 
The system will be modified - continue? [No] Y
Notify Zimbra of your installation? [Yes] N
```

###### 

3. **web登陆**

```bash
https://mail.inadm.com					# 客户端访问
https://mail.inadm.com					# Admin访问
	# User: admin
    # Pass: MoPTeqJkB
```

###### 

4. **常用命令**

```bash
su - zimbra
zmcontrol -v                    			# 查看版本
zmcontrol status                			# 查看服务状态
zmcontrol start/stop/restart    			# 开启/停止/重启
```

###### 

5. **https配置 3种配置方法**

- 使用未合并证书配置方式
```bash [1]
cat 3-CAChains.crt 2-CAChains-2.crt 1-ADDTrust-Root.crt > commercial_ca.crt	# 使用未拆分的证书进行合并,合并完成检查证书内容是否完整或者按照3/2/1顺序手动合成
mv START-XXX-COM.crt commercial.crt			# 将START的crt证书改名为commercial.crt
mv START-XXX-com.key commercial.key			# key证书改名为commercial.key
/opt/zimbra/bin/zmcertmgr verifycrt comm commercial.key commercial.crt commercial_ca.crt			# 校验证书是否成功,成功则执行下面命令。失败则根据报错找原因
/opt/zimbra/bin/zmcertmgr deploycrt comm commercial.crt commercial_ca.crt	# 应用证书，将证书写入配置。确认无报错则成功
zmcontrol restart					# 重启,使配置生效。确认无报错则成功
```

###### 

- 使用合并证书配置方式
```bash [2]
cd /opt/zimbra/ssl/zimbra/commercial
mv mail-Domian-com.key commercial.key			# key证书修改为指定名称
mv mail-Domian-com-fixed.pem commercial_ca.crt		# 合并后的证书文件修改为指定名称
mv mail-Domain-com.pem commercial.crt
/opt/zimbra/bin/zmcertmgr verifycrt comm commercial.key commercial.crt commercial_ca.crt			# 校验证书是否成功,成功则执行下面命令。失败则根据报错找原因
/opt/zimbra/bin/zmcertmgr deploycrt comm commercial.crt commercial_ca.crt	# 应用证书，将证书写入配置。确认无报错则成功
zmcontrol restart					# 重启,使配置生效。确认无报错则成功
```

###### 

- 使用阿里云免费证书配置方式 [参考文章](https://www.itgeeker.net/category/zimbra/)
阿里云平台需要有对应域名。申请免费域名证书，选择"其它"证书下载
```bash [3]
# 阿里云免费证书文件名: mail.Domian.com.pem、mail.Domian.com.key 
# 需将上面2个文件拆分和使用命令配置为三个文件: commercial.crt、commercial_ca.crt、commercial.key

# commercial.crt 文件配置:
	mail.Domian.com.pem 第一部分

# commercial_ca.crt 文件配置: 
	mail.Domian.com.pem 第二部分 + 阿里云免费ssl根证书

# commercial.key 文件使用命令生成后将privkey.pem修改为此文件名
openssl pkcs8 -topk8 -inform PEM -in mail.Domian.com.key -outform PEM -nocrypt -out privkey.pem
	# mail.Domian.com.key 为阿里云申请的key文件
```
```bash 阿里云免费ssl的根证书
-----BEGIN CERTIFICATE-----
MIIDrzCCApegAwIBAgIQCDvgVpBCRrGhdWrJWZHHSjANBgkqhkiG9w0BAQUFADBh
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBD
QTAeFw0wNjExMTAwMDAwMDBaFw0zMTExMTAwMDAwMDBaMGExCzAJBgNVBAYTAlVT
MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
b20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IENBMIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4jvhEXLeqKTTo1eqUKKPC3eQyaKl7hLOllsB
CSDMAZOnTjC3U/dDxGkAV53ijSLdhwZAAIEJzs4bg7/fzTtxRuLWZscFs3YnFo97
nh6Vfe63SKMI2tavegw5BmV/Sl0fvBf4q77uKNd0f3p4mVmFaG5cIzJLv07A6Fpt
43C/dxC//AH2hdmoRBBYMql1GNXRor5H4idq9Joz+EkIYIvUX7Q6hL+hqkpMfT7P
T19sdl6gSzeRntwi5m3OFBqOasv+zbMUZBfHWymeMr/y7vrTC0LUq7dBMtoM1O/4
gdW7jVg/tRvoSSiicNoxBN33shbyTApOB6jtSj1etX+jkMOvJwIDAQABo2MwYTAO
BgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUA95QNVbR
TLtm8KPiGxvDl7I90VUwHwYDVR0jBBgwFoAUA95QNVbRTLtm8KPiGxvDl7I90VUw
DQYJKoZIhvcNAQEFBQADggEBAMucN6pIExIK+t1EnE9SsPTfrgT1eXkIoyQY/Esr
hMAtudXH/vTBH1jLuG2cenTnmCmrEbXjcKChzUyImZOMkXDiqw8cvpOp/2PV5Adg
06O/nVsJ8dWO41P0jmP6P6fbtGbfYmbW0W5BjfIttep3Sp+dWOIrWcBAI+0tKIJF
PnlUkiaY4IBIqDfv8NZ5YBberOgOzW6sRBc4L0na4UU+Krk2U886UAb3LujEV0ls
YSEY1QSteDwsOoBrp+uvFRTp2InBuThs4pFsiv9kuXclVzDAGySj4dzp30d8tbQk
CAUw7C29C79Fv1C5qfPrmAESrciIxpg0X40KPMbp1ZWVbd4=
-----END CERTIFICATE-----
```
```bash 验证、应用证书
mv commercial_ca.crt commercial.crt commercial.key /opt/zimbra/ssl/zimbra/commercial
chown -R zimbra.zimbra /opt/zimbra/ssl/zimbra/commercial
su - zimbra
cd /opt/zimbra/ssl/zimbra/commercial
/opt/zimbra/bin/zmcertmgr verifycrt comm commercial.key commercial.crt commercial_ca.crt	# 校验证书是否成功,成功则执行下面命令。失败则根据报错找原因
/opt/zimbra/bin/zmcertmgr deploycrt comm commercial.crt commercial_ca.crt	# 应用证书，将证书写入配置。确认无报错则成功
zmlocalconfig -e ldap_starttls_required=false
zmlocalconfig -e ldap_starttls_supported=0
zmcontrol restart								# 重启,使配置生效。确认无报错则成功
```
![upload successful](/images/pasted-42.png)

###### 

6. **白名单设置**

```bash 限制邮件域发送接收邮件
# su - zimbra
# vim /opt/zimbra/conf/zmconfigd/smtpd_sender_restrictions.cf
check_sender_access lmdb:/opt/zimbra/conf/restricted_senders                # 此配置行写在顶部
 
# vim /opt/zimbra/conf/zmconfigd.cf
276     POSTCONF    smtpd_restriction_classes      local_only
277     POSTCONF    local_only                                 FILE  postfix_check_recipient_access.cf
 
# vim /opt/zimbra/conf/postfix_check_recipient_access.cf                     # 创建此文件
check_recipient_access lmdb:/opt/zimbra/conf/local_domains, reject
 
// 外发: 写在此文件中的受限，不在此文件中的不受限;受限用户或受限域只能二选其一方式配置
# vim /opt/zimbra/conf/restricted_senders                                    # 创建此文件;受限域名或用户配置在此文件中;必须遵循语法格式
user@yourdomain.com local_only                                               # 例: 限制单个用户格式
yourdomain.com local_only                                                    # 例: 限制域的所有用户格式
// 接收: 
# vim /opt/zimbra/conf/local_domains                                         # 创建此文件;受限域名或用户配置在此文件中;必须遵循语法格式
yourdomain.com OK

# 以上设置以后,"restricted_senders"文件中定义的用户仅能发送给"local_domains"定义的域中。未在受限文件中的用户,完全有任何地方发送邮件权限,此设置无法在升级中保留,升级时需备份此文件
```
```bash 重启配置生效
postmap /opt/zimbra/conf/restricted_senders
postmap /opt/zimbra/conf/local_domains 
zmmtactl stop
zmmtactl start
```

###### 

7. **阿里云主机部署Zimbra需申请放行25端口** [参考文章: 艾利克斯部落](https://www.chenxie.net/archives/2279.html)

![upload successful](/images/pasted-46.png)

###### 

