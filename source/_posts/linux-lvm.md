title: lvm 磁盘管理工具
tags:
  - Server
date: 2019-06-21 07:20:16
---
+ **LVM Linux 磁盘管理工具**
  - 逻辑扩展磁盘空间大小和缩减磁盘空间大小
  - 多个硬盘或者多个分区均可使用LVM卷组管理

###### 
<!--more-->


```bash lvm 卷类型
    PV 		# 物理卷
    VG		# 卷组
    LV		# 逻辑卷
    PE		# 物理盘区,默认大小4.00 MiB
    LE		# 逻辑盘区

# lvm 创建顺序和缩减顺序
创建顺序：PV——>VG——>LV
缩减顺序：LV——>VG——>PV
```

```bash
# libudev-devel 不安装会影响lvcreate命令正常执行
yum -y install lvm2 libudev-devel		# lvm包和依赖包
```

1. 命令介绍

| 类型 | pv命令 | vg命令 | lv命令 | 备注 |
| ------ | ------ | ------ | ------ |------ |
| 查看 | pvdisplay | vgdisplay | lvdisplay | 详细查看 |
| 查看 | pvscan | vgscan | lvscan |  |
| 查看 | pvs | vgs | lvs | 简单查看,常用 |
| 创建 | pvcreate | vgcreate | lvcreate |
| 扩展 | ------ | vgextend | lvextend |
| 缩减 | ------ | vgreduce | lvreduce |
| 删除 | pvremove | vgremove | lvremove |


```bash 命令选项介绍
例: lvcreate -L +SIZE(K、M、G、T) /dev/CentOS7_VGName/lvname
    # +SIZE	"+"表示扩展多少！！！
    # SIZE	不带"+"表示扩展到多少SIZE！！！
    # -L 大写,表示使用扩展到多少SIZE,使用单位(K、M、G、T)
    # -l 小写,表示使用PE数量(默认扩展,推荐使用方法)
```

###### 

2. 创建

```bash 整盘创建lv
lsblk							# 查看磁盘信息
pvcreate /dev/sd{b,c}					# 创建pv
vgcreate CentOS7_VGName /dev/sd{b,c}			# 创建vg
vgdisplay CentOS7_VGName|awk '/Total PE/{print $3}'	# 获取PE总数
lvcreate -l 38398 -n lvname CentOS7_VGName		# 创建lv
```
```bash 挂载磁盘
# 使用UUID方式挂在磁盘
mkfs.xfs -f /dev/CentOS7_VGName/lvname				# [1]格式化lv为xfs
mkfs.ext4 /dev/CentOS7_VGName/lvname				# [2]格式化lv为ext4
blkid /dev/CentOS7_VGName/lvname |awk -F \" '{print $2}'	# 获取uuid
# 写入fstab
echo "UUID=e0c284c9-9b15-4623-a434-65a162d158f1 /data                    xfs    defaults        0 0" >> /etc/fstab
[ ! -d /data ] && { mkdir /data;} && mount -a			# 挂载到"/data"目录
```
![upload successful](/images/pasted-1.png)

![upload successful](/images/pasted-2.png)

###### 

3. 扩展VG

```bash 扩展vg
lsblk							# 查看新增磁盘盘符信息
pvcreate /dev/sdd					# 创建pv
vgs							# 查看vg未扩展前信息
vgextend CentOS7_VGName /dev/sdd			# 新增pv到vg中
vgs							# 查看vg新增后信息
```

###### 

4. 扩展LV

```bash 扩展lv
lvs							# 查看lv未扩展前信息
vgdisplay CentOS7_VGName|awk '/Total PE/{print $3}'	# 获取PE总数量
lvextend -l 51197 /dev/CentOS7_VGName/lvname		# 扩展lv
lvs							# 查看lv扩展后信息
```
```bash 扩展文件系统
xfs_growfs /dev/CentOS7_VGName/lvname			# [1]xfs格式扩展文件系统方式
resize2fs /dev/CentOS7_VGName/lvname			# [2]ext4格式扩展文件系统方式
e2fsck -f /dev/CentOS7_VGName/lvname			# 检测磁盘
```
![upload successful](/images/pasted-3.png)

###### 

5. 缩减LV

```bash 缩减lv
# xfs格式不支持缩减
# 以下为ext4缩减
e2fsck -f /dev/CentOS7_VGName/lvname			# 缩减前,强烈建议检测一次,检查是否有磁盘错误
umount /data						# 缩减需要卸载挂载
resize2fs /dev/CentOS7_VGName/lvname +51G		# 缩减逻辑边界;缩减51G
e2fsck -f /dev/CentOS7_VGName/lvname			# 强制检测
lvreduce -L -51G /dev/CentOS7_VGName/lvname		# lv减小51G
e2fsck -f /dev/CentOS7_VGName/lvname			# 检测磁盘
lvs							# 查看lv大小
```

###### 

6. 缩减VG

```bash vg缩减
vgs							# 查看vg缩减前信息
pvmove /dev/sdb /dev/sdd				# 将sdb盘数据迁移到sdd盘
vgreduce CentOS7_VGName /dev/sdb			# 将sdb移除vg
vgs							# 查看vg缩减后信息
```

###### 

7. 删除

```bash lv/vg/pv 删除
# lv 磁盘上无数据情况下,可直接删除
lvremove /dev/CentOS7_VGName/lvname
vgremove CentOS7_VGName
pvremove /dev/sd{b,c,d}
```

###### 







