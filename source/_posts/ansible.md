title: ansible 自动化运维工具
tags:
  - Server
date: 2019-06-16 07:55:47
---
+ **Ansible 批量命令下发工具**
  - 自动化运维工具
  - 无需Agent,管理节点直接远程SSH管理被管理节点

###### 
<!--more-->

1. **Ansible 配置文件**
```bash
cat /etc/ansible/ansible.cfg 
    #inventory      = /etc/ansible/hosts         # 资源清单
    #library        = /usr/share/my_modules/     # 指向存放ansible模块的目录。支持多目录方式，使用（:）隔开
    #forks          = 5                          # 默认最多5个进程并行处理
    #sudo_user      = root                       # 默认执行目录的用户，也可以在playbook中重新设置这个参数
    remote_port    = 22                          # 默认被连接管节点
    host_key_checking = False                    # 是否检查SSH主机密钥;True检查、False不检查
    timeout = 10                                 # SSH连接超时间隔，单位秒
    log_path = /var/log/ansible.log              # 默认系统不记录日志。执行ansible用户需有写入日志权限
```

###### 

2. **Ansible 用法**

```bash
ansible ip -i Host.conf -uUserName -b -k -m shell -a "hostname"
    ip            				# Hosts文件中第一行[ip]。也可直接用all,表示所有
    -i            				# 后面指定批量执行内容，常用于IP地址
    -u            				# 指定用户名
    -b            				# 权限提升;默认sudo
    -k            				# 请求连接密码
    -m            				# 后面指定模块名script/shell等
    -T            				# 超时时间
    -f            				# 并行进程数量，默认5
    -a            				# 调用模块的参数（yum模块使用:name=xxx state=started or present）
    -o            				# 单行压缩输出
    -e            				# 定义变量
    -v            				# 显示详细信息
    --verbose            			# 查看输出细节
```

###### 

3. **Inventory 内存参数**
```bash 端口+密码方式
# 参数			解释				例子
ansible_ssh_port   定义hosts ssh 端口		ansible_ssh_port=8220
ansible_ssh_user   定义hosts ssh 认证用户		ansible_ssh_user=User01
ansible_ssh_pass   定义hosts ssh 认证密码	   	ansible_ssh_pass='123456'	
ansible_sudo	   定义hosts sudo 用户	    	ansible_sudo=User01
ansible_sudo_pass  定义hosts sudo 密码		ansible_sudo_pass='123456'
```
```bash ssh_key方式
# 定义批量密码
[all:vars]
ansible_ssh_private_key_file="/root/.ssh/key"
```

###### 

4. **Ansible 模块介绍**

```bash shell模块 和 script模块
# 直接将命令传递到远端主机执行
ansible ip -i Host.conf -uUserName -b -k -m shell -a "hostname"

# 将本地脚本文件传到到远端主机执行
ansible ip -i Host.conf -uUserName -b -k -m script -a "vm_update.sh"
```

```bash copy 模块 [复制文件到远程主机]
# src:复制本地文件到远程主机,绝对路径和相对路径都可,路径为目录时会递归复制.若路径以"/"结尾
  ,只复制目录里的内容,若不以"/"结尾,则复制包含目录在内的整个内容,类似于rsync
# dest:必选项。远程主机的绝对路径，如果源文件是一个目录,那该路径必须是目录

# backup:覆盖前先备份原文件，备份文件包含时间信息。有两个选项:yes|no
# force:若目标主机包含该文件,但内容不同,如果设 置为yes，则强制覆盖,设为no
   ,则只有当目标主机的目标位置不存在该文件时才复制。默认为yes

ansible all -k -m copy -a 'src=/etc/resolv.conf dest=/etc/resolv.conf'		# 直接覆盖文件
ansible all -k -m copy -a 'src=/etc/yum.repos.d/ dest=/etc/yum.repos.d/'	# 复制目录下的所有文件
```

```bash yum 模块
# 使用yum包管理器来管理软件包
    1. name:要进行操作的软件包名字
    2. state: 动作(installed， removed)

ansible db -k -m yum -a 'name="mariadb" state=installed'	# 安装
ansible db -k -m yum -a 'name="mariadb" state=removed'		# 卸载
```

```bash service 模块
# name:必选项，服务名称
# enabled:是否开机启动 yes|no
# sleep:执行restarted，会在stop和start之间沉睡几秒钟
# state:对当前服务执行启动，停止、重启、重新加载等操作
	started，stopped，restarted，reloaded

# 例: 关闭firewalld服务且开机自启关闭
ansible other -k -m service -a 'name="firewalld" enabled="no" state="stopped"'
ansible other -k -m service -a 'name="firewalld" state="stopped"'
```

```bash lineinfile模块 和 replace模块
# lineinfile模块
	# 类似sed的一种行编辑替换模块
	# path 目标文件文件
	# regexp 正则表达式，要修改的行
	# line 最终修改的结果
# 匹配到的行全部删除,添加上去的行必选写全;
ansible db -m lineinfile -a 'path="/etc/my.cnf" regexp="^binlog-format" line="binlog-format = row"'


# replace模块
	# 类似sed的一种行编辑替换模块
	# path 目的文件
	# regexp 正则表达式
	# replace 替换后的结果
# 精确匹配的字符串进行替换
ansible db -m replace -a 'path="/etc/my.cnf" regexp="= row$" replace="= mixed"'
```

```bash setup 模块
# 主要用于获取主机信息，playbooks里经常会用的另一个参数gather_facts与该模块相关
  setup模块下经常用的是filter参数
# filter过滤所需信息
ansible other -k -m setup
ansible other -k -m setup|grep ansible_user_uid
ansible other -k -m setup -a 'filter=ansible_user_uid'
```


######