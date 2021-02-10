title: ntp 服务部署
tags:
  - Linux-service
date: 2019-12-08 21:35:15
---
+ **NTP IDC企业机房内网时间服务器部署**
  - NTP 服务端部署
  - NTP 客户端部署
  - NTP 时间相关查询命令

<font size=2>当企业服务器达到一定规模后又需要考虑安全问题时,隔离外网必不可少。但是隔离外网后,各服务器本地时间同步又会存在校准问题。
  如果Linux各服务器之间时间不同步,通信必然存在故障。此时部署机房内部时间服务器必不可少。</font>

###### 
<!--more-->

1.1 **部署环境**
```bash 部署基础环境
1. centos 7 os
2. domain: ntp.inadm.com
3. ntp_server: 172.16.10.100
4. ntp_client: 172.16.10.200
```

2.1 **NTP 服务端部署**
```bash NTP 安装
// NTP 服务端和客户端只需安装ntp和ntpdate 2个包即可
# yum -y install ntp ntpdate

// 时区每台服务器上均需设置
# timedatectl set-timezone Asia/Shanghai
```

```bash NTP服务端部署
// NTP服务端部署强烈推荐高可用,如有硬件做VIP更佳,没有则其它替代也行例如Keepalived
// 如果做高可用,2台服务端配置文件做一模一样配置即可,无需互相同步时间。服务端会自动同步设定的外网时钟

# egrep -v "^$|^#" /etc/ntp.conf
// 系统时间与BIOS事件的偏差记录。如果关机维护了,BIOS时间还在正常运行,但系统时间已未运行,drift则是记录到关机后的最后一刻记录,开机后会根据此文件核对效验
driftfile /var/lib/ntp/drift
// 日志目录定义,可有可无,不定义则默认在/var/log/messages中
logfile	/data/logs/ntp/ntpd.log
// 默认拒绝所有ipv4客户端的所有操作
restrict default kod nomodify notrap nopeer noquery
    restrict                                                # 控制相关权限
    default                                                 # 默认所有地址
    kod:                                                    # 访问违规时发送KoD包 
    nomodify                                                # 用户端不能使用ntpq,ntpc修改时间服务器,但可以校验时间
    notrap                                                  # 不提供trap远端登陆: 拒绝为匹配的主机提供模式 6 控制消息陷阱服务。陷阱服务是 ntpdq 控制消息协议的子系统,用于远程事件日志记录程序
    nopeer                                                  # 用于阻止主机尝试与服务器对等,并允许欺诈性服务器控制时钟
    noquery                                                 # 不提供客户端的时间查询: 用户端不能使用ntpq,ntpc等命令来查询ntp服务器
// 默认拒绝所有ipv6客户端的所有操作
restrict -6 default kod nomodify notrap nopeer noquery
// 允许本机ipv4所有操作
restrict 127.0.0.1
// 允许本机ipv6所有操作
restrict -6 ::1
// 以下2条配置表示,当外部时间不可用时,使用本机时间;stratum 层级
server 127.127.1.0
fudge 127.127.1.0 stratum 10
// 允许内网哪些段内机器连接这台服务器同步时间。但是不允许修改服务器上的时间和不提供trap这个远程事件登入
restrict 172.16.10.0 mask 255.255.255.0 nomodify notrap
// 服务端向外部哪些时钟进行同步时间,可写多个但建议只写同一厂商
server ntp1.aliyun.com [iburst] minpoll 4 maxpoll 10
    prefer          					    # 优先级最高
    burst           					    # NTP服务端自身可用时,发送相关并发包检测
    iburst          					    # NTP服务端自身对外不可用时,发送相关并发包检测,达到快速同步效果
// 允许哪些时钟修改本机时间,如上条配置写多个,建议这里写一样多
restrict ntp1.aliyun.com nomodify notrap nopeer noquery
// 最后2条配置保持默认,不做介绍
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
```

```bash 硬件时钟配置
// NTP服务会在同步完系统时间后根据此配置将系统时间同步到硬件时间
grep -q "SYNC_HWCLOCK" /etc/sysconfig/ntpd && sed -i '/SYNC_HWCLOCK/ s/.*/SYNC_HWCLOCK=yes/ /etc/sysconfig/ntpd' || echo "SYNC_HWCLOCK=yes" >> /etc/sysconfig/ntpd
```

```bash 启动NTP服务
// 配置文件更改完之前不要启动NTP服务
// 启动NTP服务之前先ntpdate更新一次时间
// 如果本地时间与获取更新时间相差较大,NTP服务会认为是人为手动更改了,则不在进行同步更新
# ntpdate ntp1.aliyun.com
# systemctl start ntpd && systemctl enable ntpd
// 启动NTP服务之后,此服务和其它服务不同,不是立即生效。需等待1到5分钟
```

![upload successful](/images/pasted-52.png)

3.1 **NTP 客户端部署**
```bash
// 客户端仅只需修改一行配置即可

# egrep -v "^$|^#" /etc/ntp.conf
driftfile /var/lib/ntp/drift
restrict default nomodify notrap nopeer noquery
restrict 127.0.0.1 
restrict ::1
// 将默认server行注释,配置服务端配置
server ntp.inadm.com iburst minpoll 4 maxpoll 10
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
disable monitor
```
![upload successful](/images/pasted-56.png)

```bash 硬件时钟配置
// NTP服务会在同步完系统时间后根据此配置将系统时间同步到硬件时间
grep -q "SYNC_HWCLOCK" /etc/sysconfig/ntpd && sed -i '/SYNC_HWCLOCK/ s/.*/SYNC_HWCLOCK=yes/ /etc/sysconfig/ntpd' || echo "SYNC_HWCLOCK=yes" >> /etc/sysconfig/ntpd
```

```bash
// 服务端同步已生效后在进行客户端同步
# ntpdate ntp.inadm.com
# systemctl start ntpd && systemctl enable ntpd
```

4.1 **NTP 时间相关查询命令**
<font size=2>以下4个命令可检查和验证NTP是否已生效,系统时间、硬件时间是否已同步并生效</font>


```bash ntpq
# ntpq -p
remote: 本机所连接的上层NTP服务器，最左边符号含义：
    [*] 前正在使用的上层NTP服务器
    [+] 连上了上层NTP服务器，但为使用,待使用状态
    [-] 同步的该NTP服务器被认为不合格
    [x] 同步的外网NTP服务器不可用
refid: 指的是给上层NTP服务器提供时间校对的服务器
St: 上层NTP服务器的级别。
When: 上一次与上层NTP服务器进行时间校对的时间（单位：s)
Poll: 本地主机与上层NTP服务器进行时间校对的周期（单位：s）
reach: 已经向上层 NTP 服务器要求更新的次数 
delay: 网络传输过程钟延迟的时间 单位为 10^(-6) 秒 
offset: 时间补偿的结果 单位为10^(-6) 秒
jitter: Linux 系统时间与BIOS硬件时间差 单位为 10^(-6) 秒
```
![upload successful](/images/pasted-57.png)

```bash ntpstat 
# ntpstat 
// 可以看到NTP已正常在进行时间同步,在第3层同步到
// 时间校正耗时及每多长时间轮询一次
```
![upload successful](/images/pasted-58.png)

```bash hwclock
# hwclock -r
// 查看硬件时间。当系统时间更新完成后,硬件时间会稍慢些同步生效
```

```bash timedatectl
# timedatectl
// NTP enabled: yes			# 表示是否开机自启了
// NTP synchronized: yes		# 系统时间同步完成,状态会变为yes
```
![upload successful](/images/pasted-59.png)

###### 
