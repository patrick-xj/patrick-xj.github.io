title: ansible 自动化运维工具
tags:
  - Server
date: 2019-06-16 07:55:47
---
+ **Ansible 批量命令下发工具**
  - 自动化运维工具
  - 无需Agent,管理节点直接远程SSH管理被管理节点
+ [**Ansible 自动化运维不同运用**](https://docs.ansible.com/playbooks_roles.html)
  - Ansible 命令行用法
  - Ansible-playbook 剧本
  - Ansible-playbook roles可重复利用的剧本

###### 
<!--more-->

+ **<font size=4>Ansible 命令行用法</font>**

1.1 **Ansible 配置文件**

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

1.2 **Ansible 用法**

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

1.3 **Inventory 内存参数**
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

1.4 **Ansible 模块介绍**

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

+ **Ansible-playbook 剧本用法**
2.1 **Ansible-playbook 剧本**

  - 将需要完成的任务写到xxx.yml剧本中以单个文件方式完成编写的playbook


```bash 以下展示一个httpd安装的剧本,后面进行逐行注解其意
# cat hosts 
[web]
172.16.10.86 http_port=8080 server_name="www.inadm.com"

# cat files/httpd.conf.j2
42 Listen {{ http_port }}
95 ServerName {{ server_name }}

# cat httpd_install.yml
- hosts: all
  vars:
  - packges: httpd
  - service: httpd
  tasks:
  - name: install httpd
    yum: name={{ packges }} state=latest
    tags:
    - always
  - name: copy httpd.conf
#   copy: src=files/httpd.conf dest=/etc/httpd/conf/httpd.conf
    template: src=files/httpd.conf.j2 dest=/etc/httpd/conf/httpd.conf
    notify:
    - restart httpd
    tags:
    - web_conf
  - name: start and enable httpd
    service: name={{ service }} state=started enabled=true
  handlers:
  - name: restart httpd
    service: name={{ service }} state=restarted
# ansible-playbook -i hosts -b -k -uroot ./httpd_install.yml
# ansible-playbook -i hosts -b -k -uroot ./httpd_install.yml --tags=web_conf	# 表示仅执行tags相关的模块,其它模块不执行
```

```bash hosts文件
1. hosts文件中必须定义主机名或者IP地址
2. "host_port"和"server_name"表示定义的变量名称。等于号后面表示定义的变量值。
   此变量名可在httpd.conf.j2模板文件中以花括号方式调用,例: {{ http_port }}
```
```bash httpd.conf.j2模板
1. 模板文件需事先准备好并放到指定目录
2. 模板文件中需修改地方可以hosts文件中定义好的变量名替代
```
```bash httpd_install.yml文件
1. hosts: all 此处"all"是ansible自带特殊变量,表示hosts文件中的所有IP地址或主机名。也可仅定义"web"主机组,表示只会执行web主机组下的相关IP地址
2. vars:  用于自定义ansible的变量。下文调用此变量时也需按照固定花括号格式。变量值可以是一样
3. tasks: 表示所需要执行的任务。以不同模块完成所需要执行完成的任务,固定格式必须是"- name:"开始与之"tasks:"对齐
  yum:        # 安装模块。默认即是latest状态,表示获取最新的包
  copy:       # 复制模块。src表示源文件位置;dest表示目标文件位置
  template:   # 用于模板,模板文件中可定义相关变量。.j2仅表示见名知意用途
  service:    # 启动服务模块
  notify:     # service模块只有启动功能。当httpd.conf配置文件发生变化后,需要仅只重启服务而不执行其它模块时使用notify,用于传递给handlers执行重启
  tags:       # 当此yml文件执行过一次之后,如httpd.conf配置文件需要发生变化,但仅只需要template执行,即可使用tags模块; conf定义tags的名称
4. handlers: 接收notify传递的信号并执行传递进来的指定变量的模块
```

###### 

+ **Ansible-playbook roles可重复利用的剧本**
3. **roles文件内各文件夹所代表的角色**
  - <font size=1>tasks目录, 至少应该包含一个名为main.yml的文件,其定义了此角色的任务列表,此文件可以使用include包含其它的位于此目录中的task文件</font>
  - <font size=1>files目录, 存放有copy或script等模块调用的文件</font>
  - <font size=1>templates目录, template模块会自动在此目录中寻找jinja2模板文件</font>
  - <font size=1>handlers目录, 此目录中应当包含一个main.yml文件,用于定义此角色用到的各handler。在handler中使用include包含的其它的handler文件也应该位于此目录中</font>
  - <font size=1>vars目录, 应当包含一个main.yml文件, 用于定义此角色用到的变量</font>
  - <font size=1>mate目录, 应当包含一个main.yml文件, 用于定义角色的特殊设定其依赖关系</font>
  - <font size=1>default目录, 为当前角色设定默认变量时使用此目录。应当包含一个main.yml文件</font>

+ **将需要完成的任务写到roles定义的各自角色中**

```bash 以下将展示httpd和myslq 2个服务安装在1台服务器和mysql 这1个服务安装到另外一台单独服务器上
// httpd yml
# mkdir inventory
# mkdir -p roles/{web,db}/{files,templates,mate,handlers,vars,tasks}
# cp /path/httpd.conf roles/web/files/
# vim roles/web/tasks/main.yml
- name: install httpd
  yum: name={{ package }} state=latest
- name: copy configuration file
  template: src=httpd.conf.j2 dest=/etc/httpd/conf/httpd.conf
  tags:
  - web_conf
  notify:
  - restart httpd
- name: start and enable httpd
  service: name={{ service }} state=started enabled=true
# vim roles/web/handlers/main.yml			# notify会将信号专递到handlers目录的main.yml中
- name: restart httpd
  service: name={{ service }} state=restarted
# cat roles/web/vars/main.yml				# 变量定义;templates和tasks均可调用
http_port: 8080
server_name: www.inadm.com
package: httpd
service: httpd
# cat roles/web/templates/httpd.conf.j2
42 Listen {{ http_port }}
5 ServerName {{ server_name }}
```
```bash mysql yml
# cp /path/my.cnf roles/db/files/
# roles/db/tasks/main.yml
- name: install mysql-server packege
  yum: name=mysql-server state-latest

- name: instal configuration file
  copy: src=my.cnf dest=/etc/my.cnf
  tags:
  - myconf
  notify:
  - restart mysqld
- name: start myslqd
  service: name=mysqld enabled=true state=started
# vim roles/db/handlers/main.yml
- name: restart mysqld
  service: name=mysqld state=restarted
```
```bash
# cat inventory/hosts 
[websers]
172.16.10.86
[dbsers]
172.16.10.87
# vim deploy.yml
- hosts: websers
  roles:
  - web
  - db
- hosts: dbsers
  roles:
  - db
# ansible-playbook -i inventory/hosts -k -uroot ./deploy.yml
# ansible-playbook -i inventory/hosts -k -uroot ./site.yml tags=web_conf	# 仅执行tags部分,其余任务的模块不执行
```

###### 