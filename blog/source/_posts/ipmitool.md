title: ipmitool 服务器管理工具
tags:
  - Server
date: 2019-06-21 07:30:48
---
+ **IPMITool可远程管理物理服务器**
  - 独立于系统、BIOS,是需要通电就可以远程开机关机、获取服务器硬件状态信息

###### 
<!--more-->

1. **IPMITool 所需模块**

```bash
lsmod | grep ipmi                # 查询加载了哪些模块
modprobe ipmi_msghandler         # 加载相关模块
modprobe ipmi_devintf
modprobe ipmi_si
```

2. **IPMITool 命令用法**

```bash 远程命令管理
# ipmitool -H Bmc_IP -U Bmc_UserName -a -I lanplus
    -H                        	# 指定管理网口IP地址
    -U                        	# 指定管理网口用户名
    -a                        	# 在提示符下输入密码
    -I                        	# 指定接口类型
```
```bash Linux本地物理机命令管理
ipmitool -H BMC_IP -U root -a -I lanplus 
    fru                      	# 判断品牌等
    delloem mac              	# 获取Dell Mac 地址信息，仅适用于Dell
    shell                    	# shell 交互方式
    mc reset cold            	# 强制重启ibmc
```

###### 

3. 管理网口维护、账户维护

```bash 管理网口IP修改操作
# 管理网口IP修改仅适用于物理机系统上本地命令执行,不适用于远端命令维护
ipmitool lan print                                   # 本地查看Bmc_IP
ipmitool lan set 1 ipaddr 192.168.x.x                # 本地修改Bmc_IP
ipmitool lan set 1 netmask 255.255.255.0             # 本地修改Bmc MASK
ipmitool lan set 1 defgw ipaddr 192.168.x.254        # 本地修改网关
```
```bash 管理用户维护
# ipmitool 创建用户分配权限适用于华为、浪潮服务器
# 适用于CentOS6/7 操作系统本地命令操作
ipmitool user list 1                                 # 本地命令查看通道1的用户信息
ipmitool user set name 10 User01                     # 创建Bmc管理用户User01
ipmitool user set password 2 'Pass'                  # 本地命令修改BMC root 的密码
ipmitool user set password 10 'Pass'                 # 本地命令修改新创建的BMC用户的密码
ipmitool user priv 10 4 1                            # 本地配置Bmc权限ID_10，权限4[2为User权限、3为Operator权限、4为Administrator权限]，通道1 
ipmitool user enable 10                              # 本地启用用户；disable为禁用
```
![upload successful](/images/pasted-47.png)

###### 

4. 远程命令管理

```bash 远程开关机命令
ipmitool -H Bmc_IP -U BMC_UserName -a -I lanplus power status
    power status                 # 远程查看电源状态
    power reset                  # 远程硬重启服务器
    power on                     # 远程硬开机
    power off                    # 远程硬关机

# 物理机操作系统本地操作方式
ipmitool -I open power status
```
```bash BIOS 远程设置启动项
ipmitool -H ip -U User -P Pass chassis bootdev <device>
    none			 # 不更改启动设备顺序
    pxe				 # 强制PXE引导仅一次
    disk			 # 从默认硬盘强制启动
    cdrom			 # 从CD / DVD强制启动
    bios			 # 强制启动进入BIOS设置程序

# 物理机操作系统本地操作方式
ipmitool chassis bootdev pxe	 		# 强制PXE引导仅一次
ipmitool chassis bootdev pxe options=persistent	# 永久PXE引导
```

###### 













