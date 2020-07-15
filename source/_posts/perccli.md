title: perccli 戴尔服务器管理工具
tags:
  - Server
date: 2019-06-15 07:33:55
---
+ **PERCCLI 工具适用于戴尔服务器**
  - 适用于Linux 7 OS

###### 
<!--more-->

+ **perccli 工具获取和安装**

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

+ **RAID 配置**

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

+ **JBOD 直通模式配置**

```bash JBOD模式配置
perccli /c0 show jbod                                    # 查看直通模式是否开启
perccli /c0 set jbod=on                                  # 开启直通模式
perccli /c0/eall/sall show                               # 查看有哪些磁盘为在线模式
perccli /c0/e32/s5 set jbod                              # 配置为此块磁盘为直通模式
perccli /c0/e32/s10 set good force                       # 强制设置为在线模式
```

###### 

+ **其它命令**

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






