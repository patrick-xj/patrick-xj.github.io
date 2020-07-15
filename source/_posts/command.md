title: command 基础命令
tags:
  - Linux-base
date: 2019-06-08 07:39:05
---
+ **收录和整理一些基础的常用的比较重的一些命令**
###### 
<!--more-->

1. CentOS 7 root密码修改
```bash
1.  重启系统
2.  按方向键'上下键'选择上面选项按e
3.  在linux16这行处的en_US.UTF-8后面1个空格后输入rd.break console=tty0
4.  按Ctrl+x会自动重启进入字符界面
5.  mount -o remount,rw /sysroot				# 以读写方式重新挂载根系统
6.  chroot /sysroot
7.  echo '123456'|passwd --stdin root	
8.  touch /.autorelabel						# 创建遗忘文件
9.  exit							# 退出根系统
10. reboot
```

2. 物理 cpu mem 查看方式
```bash
# 总核数 = 物理CPU个数 X 每颗物理CPU的核数 
# 总逻辑CPU数 = 物理CPU个数 X 每颗物理CPU的核数 X 超线程数

# 查看物理CPU个数
cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l

# 查看单颗物理CPU的核数;N个CPU,乘以N
cat /proc/cpuinfo| grep "cpu cores"| uniq

# 超线程数,即也是CPU核数
cat /proc/cpuinfo| grep "processor"| wc -l

# 查看cpu型号
cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c

# 查看服务器型号
dmidecode | grep "Product Name"								

# 查看内存每个插槽的内存大小
dmidecode|grep -P -A5 "Memory\s+Device"|grep Size|grep -v Range
# 打印每根内存的详细信息
dmidecode -t 17																	
# 查看最大支持内存数
dmidecode|grep -P 'Maximum\s+Capacity'
# 打印详细内存最大支持多少;目前有多少根内存	
dmidecode -t 16																	
# 查看每根内存的速率
dmidecode|grep -A16 "Memory Device"|grep 'Speed'			
```

3. nload 网络流量查询工具
```bash
# 下载编译安装
yum install -y gcc gcc-c++ ncurses-devel make wget
wget http://www.roland-riegel.de/nload/nload-0.7.4.tar.gz

# 编译安装
tar xf nload-0.7.4.tar.gz
cd nload-0.7.4
./configure
make && make install

# 常用选项及参数解释
// 选项：
    -m                  # 不显示流量图，只显示统计数据
// 参数解释：
    Incoming            # 进入流量
    Outgoing            # 出去流量
    Curr                # 当前流量
    Avg                 # 平均流量
    Min                 # 最小流量
    Max                 # 最大流量
    Ttl                 # 流量统计
```

4. dd 命令
```bash

    bs=<n>			# 指定输入和输出块大小,默认单位字节,可以后面接单位指定大小
    count=<n>			# 从输入读取的块数量
# 可以备份、覆盖数据。做一些简单的硬盘或CPU速度测试
	块默认大小单位是字节(bytes),也可在数字后跟特定的单位来指定块大小
    	G	(1024*1024*1024 bytes)
        GB	(1000*1000*1000 bytes)
        M	(1024*1024 bytes)
        MB	(1000*1000*1000 bytes)
        w	(2 bytes)
        c	(1 bytes)
dd 命令2个基本参数
    if=<inoutfile>		# 默认为标准输入
    of=<outputfile>		# 默认为标准输出
例(数据处理)：
    dd if=/dev/sda of=/dev/sdb		# 复制sda数据到sdb
    dd if=/dev/dvd of=dvd.iso		# 复制光盘数据到iso文件
    dd if=/dev/zero of=/dev/sdb2	# 擦除1个分区数据
    
    dd if=/dev/zero of=test.blk bs=1M count=100			# 创建1个100M大小块文件,且是顺序读写
```

5. 存储空间单位的区别
```bash
例：1MB=1000KB,但是1M=1024KB。单位不同标准的存储空间大小不一样
8bit=1byte	1024byte=1K	1024K=1M
1024M=1G	1024G=1T	1024T=1PB
```

6. 时间相关命令
```bash
clock           			# 显示BIOS的时间
hwclock
    -r            			# 查看现在的BIOS时间，默认为-r参数
    -w            			# 将显示的系统时间写入到BIOS（一般同步系统时间后，需强制同步BIOS时间）
    -s            			# 将硬件时间写入到系统（一般不适用这种方式）
date            			# 显示的是系统时间
    %Y    年
    %m    月
    %d    日
    %H    小时
    %M    分钟
    %S    秒
    \     转义为空格
  date +%F -d "-2day"            显示2天前的时间
  date +%F -d "+2day"            显示2天后的时间
  date +%F-%H -d "-2Hour"        显示2小时以前
  date +%F-%H -d "+2Hour"        显示2小时以后
```

7. find 查找
```bash
find                   # 查找
    -maxdepth x        # 查找深度
        !              # 取反
        -o             # 取并集(或)
        -a             # 取交集(并)
    -name              # 文件名查找
    -iname	       # 忽略大小写
    -user	       # 用户
    -group	       # 所属组
    -mtime
        +7             # 7天以前
        -7             # 7天以内，不包含7天
        7              # 第7天
    -type              # 问价类型
        f              # 文件
        d              # 目录
        c              # 字符设备文件
        b              # 块设备
例:
    find /data -type f -name "test.txt" -exec mv {} /tmp \;
    find test/ -type f -name "*.txt" | xargs -i rm {}	# 例如txt文件过多,直接rm -f *.txt时,系统会提示报错,此时使用此命令有效
```

8. 排序命令
```bash
uniq:只能取出排好序的
    -c            统计每行重复的次数
    -u            打印未重复的行;重复的行不打印
    -d            只打印重复过的行;不重复的行不打印
    -t            指定分隔符代替非空格到空格的转换
    -t:           ":"为分隔符
    -k            位置，结合-t一起使用
    -t: -k3       截取第三个

sort:排序
    -f：忽略字符大小写
    -n：以数值大小进行排序
    -r：降序;默认升序
    -R：随机排序
    -u：只保留重复的行一行;原只有一行的同时打印出来
    -k：取指定列
```
9. ping 相关命令
```bash
yum -y install gcc                                    # 依赖gcc
wget http://fping.org/dist/fping-3.10.tar.gz          # 3.10 version
tar -xf fping-3.10.tar.gz
cd fping-3.10/
./configure
make && make install
# # # # # # 
ping
    -c x			# 指定多少个数据包
    -W x			# 等待指定时间后停止ping程序的执行。当试图测试不可达主机时此选项很有用，时间单位是秒。
    -i x			# 指定发送数据包时间间隔
```