#!/bin/bash
#root下运行
#root下执行oracle权限

#修改主机名
read -p "please change hostname:" hostname
sed -i "/^HOSTNAME/c HOSTNAME=$hostname" /etc/sysconfig/network
echo "127.0.0.1 $hostname" >>/etc/hosts
#关闭防火墙
service iptables stop
chkconfig iptables off
setenforce 0
sed -i '/^SELINUX/ s/enforcing/disabled/g' /etc/selinux/config
#挂载镜像
mount -o loop /mnt/rhel-server*.iso /media/
rm -rf /etc/yum.repos.d/*
touch /etc/yum.repos.d/rhel.repo
echo -e "[rhel]\nname=rhel\nbaseurl=file:///media/\nenabled=1\ngpgcheck=0" >>/etc/yum.repos.d/rhel.repo 
yum clean all
yum makecache
yum install -y binutils* compat-libcap1* compat-libstdc++* gcc* glibc* ksh* libgcc* libstdc++* libaio* make* sysstat* elfutils-libelf-devel* unixODBC* 
#内核优化
mem_total=`free -g|grep Mem|awk '{print $2}'`
 if [ $mem_total -ge 2 -a $mem_total -lt 5 ];then
      sed -i '/^kernel.shmmax/c kernel.shmmax = 4294967295' /etc/sysctl.conf
      sed -i '/^kernel.shmall/c kernel.shmall = 1048576' /etc/sysctl.conf
 elif [ $mem_total -ge 6 -a $mem_total -lt 9 ];then
      sed -i '/^kernel.shmmax/c kernel.shmmax = 8589934591' /etc/sysctl.conf
      sed -i '/^kernel.shmall/c kernel.shmall = 2097152' /etc/sysctl.conf
 elif [ $mem_total -ge 10 -a $mem_total -lt 13 ];then 
      sed -i '/^kernel.shmmax/c kernel.shmmax = 12884901887' /etc/sysctl.conf
      sed -i '/^kernel.shmall/c kernel.shmall = 3145728' /etc/sysctl.conf
 elif [ $mem_total -ge 14 -a $mem_total -lt 17 ];then
      sed -i '/^kernel.shmmax/c kernel.shmmax = 17179869183' /etc/sysctl.conf
      sed -i '/^kernel.shmall/c kernel.shmall = 4194304' /etc/sysctl.conf
 elif [ $mem_total -ge 30 -a $mem_total -lt 33 ];then
      sed -i '/^kernel.shmmax/c kernel.shmmax = 34359738367' /etc/sysctl.conf
      sed -i '/^kernel.shmall/c kernel.shmall = 8388608' /etc/sysctl.conf
 elif [ $mem_total -ge 62 -a $mem_total -lt 65 ];then
      sed -i '/^kernel.shmmax/c kernel.shmmax = 68719476735' /etc/sysctl.conf
      sed -i '/^kernel.shmall/c kernel.shmall = 16777216' /etc/sysctl.conf
 elif [ $mem_total -ge 118 -a $mem_total -lt 121 ];then
      sed -i '/^kernel.shmmax/c kernel.shmmax = 137438953471' /etc/sysctl.conf
      sed -i '/^kernel.shmall/c kernel.shmall = 33554432' /etc/sysctl.conf
 fi
echo -e "fs.aio-max-nr = 1048576" >>/etc/sysctl.conf
echo -e "fs.file-max = 6815744" >>/etc/sysctl.conf
echo -e "kernel.shmmni = 4096" >>/etc/sysctl.conf
echo -e "kernel.sem = 250 32000 100 128" >>/etc/sysctl.conf
echo -e "net.ipv4.ip_local_port_range = 9000 65500" >>/etc/sysctl.conf
echo -e "net.core.rmem_default = 262144" >>/etc/sysctl.conf
echo -e "net.core.rmem_max = 524288" >>/etc/sysctl.conf
echo -e "net.core.wmem_default = 262144" >>/etc/sysctl.conf
echo -e "net.core.wmem_max = 524388" >>/etc/sysctl.conf
sysctl -p
#修改用户限制文件
echo -e "oracle   soft   nproc   2047" >>/etc/security/limits.conf
echo -e "oracle   hard   nproc   16384" >>/etc/security/limits.conf
echo -e "oracle   soft   nofile  1024" >>/etc/security/limits.conf
echo -e "oracle   hard   nofile  65536" >>/etc/security/limits.conf
echo -e "oracle   soft   stack   10240" >>/etc/security/limits.conf
echo -e "session required /lib64/security/pam_limits.so" >>/etc/pam.d/login
echo -e "session required pam_limits.so" >>/etc/pam.d/login
echo -e "if [ $USER = "oracle" ]; then" >>/etc/profile
echo -e   "if [ $SHELL = "/bin/ksh" ]; then" >>/etc/profile
echo -e      "ulimit -p 16384" >>/etc/profile
echo -e      "ulimit -n 65536" >>/etc/profile
echo -e   "else" >>/etc/profile
echo -e      "ulimit -u 16384 -n 65536" >>/etc/profile
echo -e   "fi" >>/etc/profile
echo -e "fi" >>/etc/profile
source /etc/profile
#创建oracle账户
groupadd dba
groupadd oinstall
useradd -d /home/oracle -m -g oinstall -G dba oracle
echo "please input oracle password:"
passwd oracle
mkdir -p /u01/app/oracle/product/11.2.0/db_1
mkdir /u01/app/oracle/oradata
mkdir /u01/app/oracle/inventory
mkdir /u01/app/oracle/fast_recovery_area
chown -R oracle:oinstall /u01/app/oracle
chmod -R 775 /u01/app/oracle
#解压缩
cd /mnt
unzip /mnt/linux.x64_11gR2_database_1of2.zip 
unzip /mnt/linux.x64_11gR2_database_2of2.zip
#免密码切换root
chmod 777 /etc/sudoers
sed -i "/^root/a oracle ALL=(ALL) ALL" /etc/sudoers
echo "oracle ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers
chmod 440 /etc/sudoers
su - oracle

