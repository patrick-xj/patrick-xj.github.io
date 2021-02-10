title: perccli 戴尔服务器管理工具
tags:
  - Server
date: 2019-06-15 07:33:55
---
+ **戴尔服务器管理工具**
  - perccli 戴尔RAID管理工具
  - iDRAC 戴尔管理平台工具 

###### 
<!--more-->

+ 1.1 **perccli 工具获取和安装**

```bash 获取安装包
# 戴尔官网使用SN查询选项驱动程序下载
    关键字：PERCCLI            操作系统：Red Hat E... Linux7
    类别：SAS RAID             格式：全部
```
```bash 安装
rpm -ivh <percli-x.xx-x.noarch.rpm> 或 rpm -iUh <percli-x.xx-x.noarch.rpm> 
/opt/MegaRAID/perccli
ln -s /opt/MegaRAID/perccli/perccli64 /bin/perccli
```

###### 

+ 1.2 **RAID 配置**

```bash Raid 0 配置
perccli /c0/eall/sall show                               # 查看在线模式硬盘
perccli /c0 add vd r0 drives=32:5 wb ra                  # 配置32:5此单块盘为raid0，读写模式wb ra
perccli /c0/eall/sall show                               # 查看在线模式硬盘
perccli /c0/v2 delete                                    # 删除raid v2，raid0配置
```
```bash Raid 1 配置
perccli /c0 add vd r1 drives=32:5,6 wb ra                # 创建raid1
perccli /c0/vall show                                    # 查看raid配置信息
perccli /c0/v2 delete                                    # 删除raid v2，raid1配置

# 创建RAID-1分2个分区
# perccli /c0 add vd r1 [size=<VD1_sz>,<VD2_sz>,..|all] drives=e:s|e:s-x|e:s-x,y,e:s-x,y,z wb ra
perccli /c0 add vd r1 size=200G drives=32:0,1 wb ra      # 创建raid1第一个分区200G
perccli /c0 add vd r1 Size=all drives=32:0-1 wb ra       # raid1剩余空间全部划分单独分区
```
```bash Raid 5 配置
perccli /c0 add vd r5 drives=32:5-7 wb ra                # 创建raid5 <需最少3块盘>
perccli /c0/vall show                                    # 查看raid配置信息
perccli /c0/v2 delete                                    # 删除raid v2，raid5配置
```
###### 

+ 1.3 **JBOD 直通模式配置**

```bash JBOD模式配置
perccli /c0 show jbod                                    # 查看直通模式是否开启
perccli /c0 set jbod=on                                  # 开启直通模式
perccli /c0/eall/sall show                               # 查看有哪些磁盘为在线模式
perccli /c0/e32/s5 set jbod                              # 配置为此块磁盘为直通模式
perccli /c0/e32/s10 set good force                       # 强制设置为在线模式
```

###### 

+ 1.4 **其它命令**

```bash
perccli show ctrlcount                                   # 查看控制器数量
perccli /c0/eall/sall show                               # 查看物理硬盘信息
perccli /c0/vall show                                    # 查信RAID配置信息
perccli /c0/fall show all                                # 查看脱机硬盘信息
perccli /c0 show jbod                                    # 查看直通模式状态和是否启用<ON为启用，OFF未关闭>
perccli /c0 set jbod=off force                           # 强制配置为关闭直通模式
perccli /c0 show bios                                    # 查看BIOS启动模式
perccli /c0 show preservedcache                          # 查看硬盘是否有缓存信息
```

###### 

+ **<font size=4>iDRAC 戴尔管理平台工具</font>**

+ 2.1 **iDRAC 工具获取和安装**

```bash 安装iDRAC工具包
wget https://downloads.dell.com/FOLDER04651962M/1/OM-MgmtStat-Dell-Web-LX-9.1.0-2771_A00.tar.gz	# 软件包地址
tar -zxf OM-MgmtStat-Dell-Web-LX-9.1.0-2771_A00.tar.gz
cd linux/rac/RHEL7/x86_64/
yum -y install net-snmp-utils pciutils
rpm -ivh *.rpm --nodeps --force
ln -s /opt/dell/srvadmin/sbin/racadm /bin/racadm
```

```bash 远程访问和本地登录交互式运行命令方式
racadm  -r 'IDRAC_IP' -u 'IDRAC_USER' -p 'IDRAC_PASS' serveraction powerstatus	# 远程执行方式
racadm serveraction powerstatus 						# 本地交互式执行方式
```

###### 

2.2 **iDRAC 开关机物理机操作**

```bash
# 查看
racadm serveraction powerstatus                          # 查看服务器状态

# 开关机
racadm serveraction powerup                              # 开启服务器
racadm serveraction powerdown                            # 关闭服务器
racadm serveraction powercycle                           # 关机后再开机
```

###### 

2.3 **iDRAC 管理口重启**

```bash 管理平台网口重启命令
racadm racreset soft                                     # 软重启iDRAC
racadm racreset hard                                     # 硬重启iDRAC
racadm racreset soft -f                                  # 强制软重启iDRAC
racadm racreset hard -f                                  # 强制硬重启iDRAC
```


###### 

2.4 **iDRAC 命令执行方式**

```bash iDRAC 用户设置
# 查询
racadm getconfig -u <UserName>                                                # 查找某个用户是否存在
racadm getconfig -g cfgUserAdmin -i 2                                         # 查看用户参数信息<索引号'2'为root用户>

# 创建用户
racadm config -g cfgUserAdmin -o cfgUserAdminUserName -i <索引> <用户名>       # 创建用户
racadm config -g cfgUserAdmin -o cfgUserAdminPassword -i <索引> <"密码">       # 给用户名设置密码

# 权限
racadm config -g cfgUserAdmin -o cfgUserAdminPrivilege -i <索引> <权限>        # 0表示所有权限；2表示User;3表示操作权限；4管理员权限；15无访问权限； 待确认权限
racadm set idrac.users.15.Privilege 0x1ff                                     # 设置为管理员 

# 修改
racadm set iDRAC.Users.2.Password 'calvin'                                    # 更改用户密码

# 禁用、启用
racadm config -g cfgUserAdmin -i 10 -o cfgUserAdminEnable 1                    # 启用用户；1启用、0禁用
racadm set idrac.users.15.enable enabled                                       # 启用用户

# 删除
racadm config -g cfgUserAdmin -o cfgUserAdminUserName -i 3 ""                  # 删除用户
```












