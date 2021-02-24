#!/bin/bash
#接oracle_install_1
#oracle账户下运行
#oracle账户执行root权限
echo "ORACLE_BASE=/u01/app/oracle" >>~/.bash_profile
echo "ORACLE_HOME=/u01/app/oracle/product/11.2.0/db_1" >>~/.bash_profile
echo "ORACLE_SID=orcl" >>~/.bash_profile
echo "PATH=$PATH:/u01/app/oracle/product/11.2.0/db_1/bin" >>~/.bash_profile
echo "export ORACLE_BASE ORACLE_HOME ORACLE_SID PATH" >>~/.bash_profile
source ~/.bash_profile
#修改安装包配置
hostname=`grep "HOSTNAME" /etc/sysconfig/network|cut -f2 -d"="`
sudo -s sed -i "/^oracle.install.option/c oracle.install.option=INSTALL_DB_SWONLY" /mnt/database/response/db_install.rsp
sudo -s sed -i "/^ORACLE_HOSTNAME/c ORACLE_HOSTNAME=$hostname" /mnt/database/response/db_install.rsp
sudo -s sed -i "/^UNIX_GROUP_NAME/c UNIX_GROUP_NAME=oinstall" /mnt/database/response/db_install.rsp
sudo -s sed -i "/^INVENTORY_LOCATION/c INVENTORY_LOCATION=/u01/app/oracle/inventory" /mnt/database/response/db_install.rsp
sudo -s sed -i "/^SELECTED_LANGUAGES/c SELECTED_LANGUAGES=en,zh_CN" /mnt/database/response/db_install.rsp
sudo -s sed -i "/^ORACLE_HOME/c ORACLE_HOME=/u01/app/oracle/product/11.2.0/db_1" /mnt/database/response/db_install.rsp
sudo -s sed -i "/^ORACLE_HOME/c ORACLE_HOME=/u01/app/oracle/product/11.2.0/db_1" /mnt/database/response/db_install.rsp
sudo -s sed -i "/^ORACLE_BASE/c ORACLE_BASE=/u01/app/oracle" /mnt/database/response/db_install.rsp
sudo -s sed -i "/^oracle.install.db.InstallEdition/c oracle.install.db.InstallEdition=EE" /mnt/database/response/db_install.rsp
sudo -s sed -i "/^oracle.install.db.DBA_GROUP/c oracle.install.db.DBA_GROUP=dba" /mnt/database/response/db_install.rsp
sudo -s sed -i "/^oracle.install.db.OPER_GROUP/c oracle.install.db.OPER_GROUP=dba" /mnt/database/response/db_install.rsp
sudo -s sed -i "/^DECLINE_SECURITY_UPDATES/c DECLINE_SECURITY_UPDATES=true" /mnt/database/response/db_install.rsp
#静默安装程序
unset DISPLAY
cd /mnt/database
./runInstaller -silent -ignorePrereq -ignoreSysPrereqs -responseFile /mnt/database/response/db_install.rsp

