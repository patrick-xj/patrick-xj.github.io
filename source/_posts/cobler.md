title: cobbler 批量装机
tags:
  - Linux-service
date: 2019-07-16 07:49:39
---
+ **Cobbler 快速批量网络安装Centos 7 System**

  - 安装、配置、启服务
  - 导入ISO镜像系统文件
  - 定义kickstarts文件
  - 使用脚本实现系统批量一键安装

###### 
<!--more-->

1. **Centos 7 cobbler 软件包安装**

```bash 安装cobbler软件包和依赖包
yum -y install epel-release
yum clean all && yum repolist
yum -y install cobbler pykickstart debmirror dhcp xinetd fence-agents
```

###### 

2. **配置文件修改**

```bash
sed -i "s/^Listen 80/Listen 9180/" /etc/httpd/conf/httpd.conf	# http默认请求80端口,可根据需求修改
sed -i '14s/yes/no/g' /etc/xinetd.d/tftp			#  tftp 配置文件修改

# cobbler 主配置文件修改
sed -i "s/^server: 127.0.0.1/server: 172.16.10.80/" /etc/cobbler/settings		# cobbler服务器IP地址
sed -i "s/^pxe_just_once: 0/pxe_just_once: 1/" /etc/cobbler/settings			# 仅安装一次
sed -i "s/^manage_rsync: 0/manage_rsync: 1/" /etc/cobbler/settings			# 启用rsync管理功能
sed -i "s/^manage_dhcp: 0/manage_dhcp: 1/" /etc/cobbler/settings			# 启用dhcp管理,用于下发分配的指定IP地址
sed -i "s/^next_server: 127.0.0.1/next_server: 172.16.10.80/" /etc/cobbler/settings
sed -i "s/^http_port: 80/http_port: 9180/" /etc/cobbler/settings			# cobbler监听端口需与apache监听端口一致

# 使用openssl生成加密密码,并将生成的加密密码修改到配置文件中
openssl passwd -1 -salt 'root' 'INadm@123'			# 生成加密密码
sed -i '101c default_password_crypted: "$1$root$L5aNw4zzLf4CQxuUxG7G8."' /etc/cobbler/settings	# 修改默认加密密码

sed -i 's/@dists="sid";/# @dists="sid";/g' /etc/debmirror.conf
sed -i 's/@arches="i386";/# @arches="i386";/g' /etc/debmirror.conf
```

###### 

3. **DHCP配置文件修改**
```bash 系统安装时,声明哪些网段可以进行网络安装
# vim /etc/cobbler/dhcp.template				# 可声明多个网段
subnet 172.16.10.0 netmask 255.255.255.0 {
     option routers             172.16.10.254;
     option subnet-mask         255.255.255.0;
     default-lease-time         21600;
     max-lease-time             43200;
     next-server                $next_server;
     class "pxeclients" {
          match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
          if option pxe-system-type = 00:02 {
                  filename "ia64/elilo.efi";
          } else if option pxe-system-type = 00:06 {
                  filename "grub/grub-x86.efi";
          } else if option pxe-system-type = 00:07 {
                  filename "grub/grub-x86_64.efi";
          } else if option pxe-system-type = 00:09 {
                  filename "grub/grub-x86_64.efi";
          } else {
                  filename "pxelinux.0";
          }
     }

}
```

###### 

4. **启动配置**

```bash
systemctl start cobblerd && systemctl enable cobblerd
systemctl start httpd && systemctl enable httpd

cobbler sync
cobbler check 
cobbler get-loaders
systemctl start rsyncd && systemctl enable rsyncd
systemctl start xinetd.service && systemctl enable xinetd
cobbler check
```

###### 

5. **导入镜像**

```bash
mount -o loop,ro /data/iso/CentOS-7-x86_64-DVD-1708.iso /media/
cobbler import --path=/media/ --name=centos7.4 --arch=x86_64
cobbler profile remove --name=centos7.4-x86_64
umount /media
```

###### 

6. **添加kickstart文件**  [参考文档](https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/7/pdf/installation_guide/Red_Hat_Enterprise_Linux-7-Installation_Guide-zh-CN.pdf)

```bash 添加profile指定新的kickstart文件
cobbler profile add --name=centos74-vm --distro=centos7.4-x86_64 --kickstart=/var/lib/cobbler/kickstarts/centos74-vm.ks
cobbler sync

```
```bash kickstart 文件定义系统安装过程中凡是需要手动配置的地方均通过ks文件实现自动化安装
# cat /var/lib/cobbler/kickstarts/centos74-vm.ks
auth --useshadow --passalgo=sha512
firewall --disabled
text
firstboot --disable
keyboard --vckeymap=us --xlayouts='us'
lang en_US.UTF-8
rootpw $1$root$L5aNw4zzLf4CQxuUxG7G8. --iscrypted
selinux --disabled
timezone Asia/Shanghai --utc --nontp
eula --agreed
url --url="http://172.16.10.80:9180/cblr/links/centos7.4-x86_64"
clearpart --all
zerombr
bootloader --location=mbr --boot-drive=sda
part / --fstype="xfs" --grow --size=1 --ondisk=sda
part swap --fstype="swap" --size=2048 --ondisk=sda
reboot

%packages
@^minimal
@core
@virtualization-client
@virtualization-hypervisor
@virtualization-tools
libguestfs-tools-c
libguestfs-tools
wget
vim
net-tools
bash-completion
kernel-devel
lrzsz
ntp
%end

%addon com_redhat_kdump --disable --reserve-mb=auto
%end

%post --log=/tmp/post_ks.log

LOCALIP=`/sbin/ip a|grep '172.16.'|grep -v '192.168.122.1'|awk '{print $2}'|awk -F/ '{print $1}'`
cat > /etc/sysconfig/network-scripts/ifcfg-ens33 <<_EOF_
TYPE=Ethernet
DEVICE=ens33
NM_CONTROLLED=no
BOOTPROTO=static
PEERDNS=no
ONBOOT=yes
IPADDR=${LOCALIP}
NETMASK=255.255.255.0
GATEWAY=172.16.10.254
_EOF_

cat > /etc/resolv.conf <<_EOF_
nameserver 8.8.8.8
nameserver 8.8.4.4
_EOF_

%end
```

###### 

7. **cobbler 脚本文件**

```bash host.conf 文件,按照指定格式填写待安装服务器的MAC地址和分配指定IP
cat host.conf 
# profiel   ip_addr         mac               
# centos74-vm 172.16.10.100 08:80:56:26:58:66
```

```bash host.conf 和 sys_vm_install.sh 需在同一目录下
cat sys_vm_install.sh 
#!/bin/bash
# Desc: system install scripts

red () {
        echo -e "\e[0;31;1m$*\e[0m"
}

green () {
        echo -e "\e[0;32;1m$*\e[0m"
}

cobbler_system_remove () {
    for SYSTEM_NAME in `cobbler system list`; do
        cobbler system remove --name=${SYSTEM_NAME}
    done
}

system_add() {
    egrep -v "^#|^$" host.conf | while read host; do
        sys_profile=$(echo ${host} | awk '{print $1}')
        vm_ip=$(echo ${host} | awk '{print $2}')
        vm_mac=$(echo ${host} | awk '{print $3}')
        vm_name_profile=$(echo ${host} | awk '{print $1}' | awk -F "-" '{print $1}')
        vm_name=$(echo ${vm_ip} | awk -F '.' '{print $3"."$4}')

        echo "--add ${vm_ip}"
        cobbler system add --name=${vm_name_profile}_${vm_name} --profile=${sys_profile} --ip-address=${vm_ip} --mac-address=${vm_mac} --interface=eth0 --netboot-enabled=1
    done

    if [ "$?" -eq 0 ];then
        cobbler sync &>/dev/null
        if [ "$?" -eq 0 ];then
                green "$(date +%m%d-%H:%M:%S) -- cobbler sync done!"
        fi
        green "$(date +%m%d-%H:%M:%S) -- all system task are:"
        cobbler system list
    fi
}

main () {
    cobbler_system_remove
    system_add
}

main
```