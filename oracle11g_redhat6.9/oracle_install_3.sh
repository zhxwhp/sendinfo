#!/bin/bash#接oracle_install_2
#oracle账户下运行
#oracle账户执行root权限
source ~/.bash_profile
sudo -s sh /u01/app/oracle/inventory/orainstRoot.sh
sudo -s sh /u01/app/oracle/product/11.2.0/db_1/root.sh
#配置监听
export DISPLAY=localhost:0.0
netca -silent -responseFile /mnt/database/response/netca.rsp
#实例名配置文件修改
sudo -s sed -i "/^GDBNAME/c GDBNAME = \"orcl\"" /mnt/database/response/dbca.rsp
sudo -s sed -i "/^SID/c SID = \"orcl\"" /mnt/database/response/dbca.rsp
sudo -s sed -i "/^#SYSPASSWORD/c SYSPASSWORD = \"oracle\"" /mnt/database/response/dbca.rsp
sudo -s sed -i "/^#SYSTEMPPASSWORD/c SYSTEMPASSWORD = \"oracle\"" /mnt/database/response/dbca.rsp
sudo -s sed -i "/^#SYSMANPASSWORD/c SYSMANPASSWORD = \"oracle\"" /mnt/database/response/dbca.rsp
sudo -s sed -i "/^#DBSNMPPASSWORD/c DBSNMPPASSWORD = \"oracle\"" /mnt/database/response/dbca.rsp
sudo -s sed -i "/^#DATAFILEDESTINATION/c DATAFILEDESTINATION = /u01/app/oracle/oradata" /mnt/database/response/dbca.rsp
sudo -s sed -i "/^#RECOVERYAREADESTINATION/c RECOVERYAREADESTINATION = /u01/app/oracle/fast_recovery_area" /mnt/database/response/dbca.rsp
sudo -s sed -i "/^#CHARACTERSET/c CHARACTERSET = \"ZHS16GBK\"" /mnt/database/response/dbca.rsp
sudo -s sed -i "/^#TOTALMEMORY/c TOTALMEMORY = \"1638\"" /mnt/database/response/dbca.rsp
dbca -silent -responseFile /mnt/database/response/dbca.rsp

