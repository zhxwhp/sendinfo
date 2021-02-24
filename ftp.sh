#!/bin/bash

setenforce 0

systemctl stop firewalld.service

systemctl disable firewalld.service

yum -y install vsftpd ftp vim

        read -p "请创建一个系统账户:" ftp_user
       
       	read -p "系统账户所管理的目录:" ftp_dir
	
	echo -e "\n"

useradd -d $ftp_dir -s /sbin/nologin $ftp_user


chown -R $ftp_user:$ftp_user $ftp_dir

cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.bak

touch /etc/vsftpd/vir_user

mkdir /etc/vsftpd/vsftpd_viruser

read -p "请输入要创建虚拟账户的个数:" account_num

i=1

while [ $i -le $account_num ];do
        
	read -p "请创建一个虚拟用户:" user
        
	read -s "请输入虚拟用户密码:" password
        
	read -p "请创建虚拟用户所管理的目录:" dir
	

	
	echo -e "\n"

#$dir在$ftp_dir下级目录或相同目录	
	
	mkdir -p $dir  
	
chown -R $ftp_user.$ftp_user $dir
	
	echo -e "$user" >>/etc/vsftpd/vir_user
        
	echo -e "$password" >>/etc/vsftpd/vir_user
	

	cd /etc/vsftpd/vsftpd_viruser
        
	touch $user

cat >$user <<EOF
write_enable=YES
anon_world_readable_only=NO
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES
anon_umask=022
local_root=$dir
EOF

let i=i+1

done

db_load -T -t hash -f /etc/vsftpd/vir_user  /etc/vsftpd/vir_user.db

chmod 700 /etc/vsftpd/vir_user.db

cp /etc/pam.d/vsftpd /etc/pam.d/vsftpd.bak
        
 	sed -i "/auth/ s/^/#/g" /etc/pam.d/vsftpd
        
	sed -i "/account/ s/^/#/g" /etc/pam.d/vsftpd
        
	echo -e "auth required pam_userdb.so   db=/etc/vsftpd/vir_user">>/etc/pam.d/vsftpd
        
	echo -e "account required pam_userdb.so   db=/etc/vsftpd/vir_user">>/etc/pam.d/vsftpd
        
	sed -i "s/anonymous_enable=YES/anonymous_enable=NO/g" /etc/vsftpd/vsftpd.conf
        
	echo -e "guest_enable=YES\nguest_username=$ftp_user\nuser_config_dir=/etc/vsftpd/vsftpd_viruser
        \nallow_writeable_chroot=YES" >>/etc/vsftpd/vsftpd.conf

	sed -i "s/^/#/g" /etc/vsftpd/ftpusers

systemctl start vsftpd.service

systemctl enable vsftpd.service

