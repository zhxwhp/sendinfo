##################################################################
##    rman_backup.sh               ##
##    created by Tianlesoftware                 ##
##        2011-2-18                         ##
##################################################################
#!/bin/bash
source /home/oracle/.bash_profile
export LANG=en_US
SCRIPT_DIR=/u01/scripts
BACKUP_DATE=`date +%d`
RMAN_LOG_FILE=/u01/scripts/rmanbackup.out
PROJECT_NAME=Sendinfo_xx
LOCAL_PATH=/u01/backupsets
REMOTE_IP=192.168.66.9
REMOTE_PATH=D:\\db_bak
REMOTE_BK_TYPE=FTP
YMD=`date +%Y%m%d`
TODAY=`date`
USER=`id|cut -d "(" -f2|cut -d ")" -f1`

# upload parameters
BACKUP_DIR=/u01/backupsets
ORACLE_SID=orcl
REV_DATE=+7
FTP_USER=db_bak
FTP_PASS="sendinfo@123"
FILE_NAME=*`date +%Y%m%d`
REMOTE_USER=db_bak
REMOTE_DIR=/home/db_backup
FTP_LOG=/u01/scripts/upload_rman.log



echo "-----------------$TODAY-------------------">$RMAN_LOG_FILE
ORACLE_HOME=/u01/app/oracle/product/12.2.0/db_1
export ORACLE_HOME
RMAN=$ORACLE_HOME/bin/rman
export RMAN
ORACLE_SID=orcl
export ORACLE_SID
ORACLE_USER=oracle
export ORACLE_USER
echo "ORACLE_SID: $ORACLE_SID" > $RMAN_LOG_FILE
echo "ORACLE_HOME:$ORACLE_HOME">>$RMAN_LOG_FILE
echo "ORACLE_USER:$ORACLE_USER">>$RMAN_LOG_FILE
echo "==========================================">>$RMAN_LOG_FILE
echo "BACKUP DATABASE BEGIN......">>$RMAN_LOG_FILE
echo "                   ">>$RMAN_LOG_FILE
chmod 666 $RMAN_LOG_FILE
WEEK_DAILY=`date +%a`
case  "$WEEK_DAILY" in
       "Mon")
            BAK_LEVEL=0
            ;;
       "Tue")
            BAK_LEVEL=0
            ;;
       "Wed")
            BAK_LEVEL=0
            ;;
       "Thu")
            BAK_LEVEL=0
            ;;
       "Fri")
            BAK_LEVEL=0
            ;;
       "Sat")
            BAK_LEVEL=0
            ;;
       "Sun")
            BAK_LEVEL=0
            ;;
       "*")
            BAK_LEVEL=error
esac
export BAK_LEVEL=$BAK_LEVEL 
echo "Today is : $WEEK_DAILY  incremental level= $BAK_LEVEL">>$RMAN_LOG_FILE
RUN_STR="
BAK_LEVEL=$BAK_LEVEL
export BAK_LEVEL
ORACLE_HOME=$ORACLE_HOME
export ORACLE_HOME
ORACLE_SID=$ORACLE_SID
export ORACLE_SID



$RMAN nocatalog TARGET / msglog $RMAN_LOG_FILE append <<EOF
run
{
allocate channel c1 type disk;
allocate channel c2 type disk;
CONFIGURE CONTROLFILE AUTOBACKUP OFF;
backup as compressed backupset  incremental level= $BAK_LEVEL  skip inaccessible filesperset 6 Database format='/u01/backupsets/orcl_lev"$BAK_LEVEL"_%U_%T'  tag='orcl_lev"$BAK_LEVEL"' ;
sql 'alter system archive log current';
backup archivelog all tag='arc_bak' format='/u01/backupsets/arch_%U_%T' skip inaccessible  filesperset 6 not  backed up 1 times  delete input;
backup current controlfile tag='bak_ctlfile' format='/u01/backupsets/ctl_file_%U_%T';
backup spfile tag='spfile' format='/u01/backupsets/orcl_spfile_%U_%T';
release channel c2;
release channel c1;
}
allocate channel for maintenance device type disk; 
crosscheck backup; 
delete noprompt expired backup;
report obsolete; 
delete noprompt obsolete;
list backup summary; 
release channel;
EOF
"

function getseqval() {
  sqlplus -S /nolog > $SCRIPT_DIR/getseqval.log 2>&1  <<EOF
  set heading off;
  set feedback off;
  set pagesize 0;
  set verify off;
  set echo off;
  conn / as sysdba
  select monitor.seq_db_backup_info.nextval from dual;
  exit
EOF


  SEQVAL=`cat $SCRIPT_DIR/getseqval.log|sed 's/[[:space:]][[:space:]]*//g'`
  export SEQVAL

  echo "seqval="$SEQVAL >> $RMAN_LOG_FILE
}


function insert_title() {
sqlplus -S / as sysdba > $SCRIPT_DIR/insert_title.log 2>&1 <<EOF
insert into monitor.db_backup_info
  (ID,
   INSTANCE_NAME,
   PROJECT_NAME,
   BACKUP_FILE_NAME,
   LOCAL_PATH,
   REMOTE_IP,
   REMOTE_PATH,
   REMOTE_BK_TYPE,
   CREATE_TIME,
   LOCAL_BK_STARTTIME,
   MESSAGE)
values
  ('$SEQVAL',
   '$ORACLE_SID',
   '$PROJECT_NAME',
    '$YMD',
   '$LOCAL_PATH',
   '$REMOTE_IP',
   '$REMOTE_PATH',
   '$REMOTE_BK_TYPE',
    sysdate,
    sysdate,
    'rman backup is now in processing');
commit;
exit;
EOF
}



# Log the completion of this script. 

function update_local() {
RESULT=`cat  $RMAN_LOG_FILE| grep "ORA-" | wc -l`
if [ $RESULT -gt 0 ]
then
  MSG=`cat $RMAN_LOG_FILE | grep "ORA-" | head -1`
  LOCAL_BK_STATUS=1
  sqlplus -S / as sysdba > $SCRIPT_DIR/update_local.log 2>&1 <<EOF
  update monitor.db_backup_info
      set LOCAL_BK_STATUS='$LOCAL_BK_STATUS',
          LOCAL_FILE_MD5='error',
          REMOTE_FILE_MD5='error',
          MODIFY_TIME=sysdate,
          LOCAL_DURATION=(sysdate-local_bk_starttime)*24*3600,
          MESSAGE='$MSG'
    where ID='$SEQVAL';
    commit;
    exit;
EOF

else
  MSG="local backup suceessed,now remote transfer processing"
  LOCAL_BK_STATUS=0
  echo "update local backup result status:" >>$RMAN_LOG_FILE
  sqlplus -S / as sysdba > $SCRIPT_DIR/update_local.log 2>&1 <<EOF
  update monitor.db_backup_info
      set LOCAL_BK_STATUS='$LOCAL_BK_STATUS',
          LOCAL_FILE_MD5='0',
          REMOTE_FILE_MD5='0',
          MODIFY_TIME=sysdate,
          LOCAL_DURATION=(sysdate-local_bk_starttime)*24*3600,
          MESSAGE='$MSG'
    where ID='$SEQVAL';
    commit;
    exit;
EOF

fi

}


function bkp_record() {
if [ $LOCAL_BK_STATUS -eq 0 ];then
   
   cd $LOCAL_PATH
   for f in `ls $LOCAL_PATH/*$YMD`;
   do
      echo $f
      md5sum $f > $f.md5
      MD5VAL=`cat $f.md5|awk '{print $1}'`
      filename=`basename $f`
      echo "file $f's MD5VAL is : "$MD5VAL >> $RMAN_LOG_FILE
      sqlplus -S / as sysdba > $SCRIPT_DIR/bkp_record.log 2>&1  <<EOF
      insert into monitor.db_backup_info
  (id,
   instance_name,
   project_name,
   backup_file_name,
   local_path,
   remote_ip,
   remote_path,
   remote_bk_type,
   local_bk_status,
   local_file_md5,
   create_time)
   values
  (monitor.seq_db_backup_info.nextval,
   '$ORACLE_SID',
   '$PROJECT_NAME',
   '$filename', 
   '$LOCAL_PATH',
   '$REMOTE_IP',
   '$REMOTE_PATH',
   '$REMOTE_BK_TYPE',
   '$LOCAL_BK_STATUS',
   '$MD5VAL',
    sysdate
  );
  commit;
  exit;
EOF
   done 
   rm -rf $LOCAL_PATH/*.md5
fi
 
}

#  upload codes
upload_ftp(){
#tar rman backupsets
cd $LOCAL_PATH
if [ $? -eq 0 ];then
#ftp upload
  cd $LOCAL_PATH
  echo "Begin start Ftp Trans"
  ftp -n -i $REMOTE_IP <<EOF > $FTP_LOG
  user $FTP_USER $FTP_PASS
  prompt
  prompt
  bin
  mput $FILE_NAME
quit
EOF

fi

}


upload_scp()
{
scp -r $BACKUP_DIR/*`date +%Y%m%d` $REMOTE_USER@$REMOTE_IP:$REMOTE_DIR/
}


remote_result() {
RESULT=`cat  $FTP_LOG| grep "Not connected" | wc -l`
if [ $RESULT -eq 0 ];then

   MSG="total backup job successful ended"
   sqlplus -S / as sysdba > $SCRIPT_DIR/remote_result.log 2>&1  <<EOF
   update monitor.db_backup_info
      set REMOTE_BK_STATUS=0,
          MODIFY_TIME=sysdate,
          REMOTE_BK_ENDTIME=sysdate,
          TOTAL_DURATION=(sysdate-local_bk_starttime)*24*3600,
          MESSAGE='$MSG'
    where ID='$SEQVAL';

    update monitor.db_backup_info t
   set (t.remote_bk_status,
        t.modify_time,
        t.local_bk_starttime,
        t.remote_bk_endtime,
        t.local_duration,
        t.total_duration,
        t.message) =
       (select remote_bk_status,
               sysdate,
               local_bk_starttime,
               remote_bk_endtime,
               local_duration,
               total_duration,
               message
          from monitor.db_backup_info b
         where b.id = '$SEQVAL')
     where id > '$SEQVAL';

commit;
exit;
EOF

else

MSG="remote backup error occured!!!!!!!!!"
   sqlplus -S / as sysdba > $SCRIPT_DIR/remote_result.log 2>&1  <<EOF
   update monitor.db_backup_info
      set REMOTE_BK_STATUS=1,
          MODIFY_TIME=sysdate,
          REMOTE_BK_ENDTIME=sysdate,
          TOTAL_DURATION=(sysdate-local_bk_starttime)*24*3600,
          MESSAGE='$MSG'
    where ID='$SEQVAL';

    update monitor.db_backup_info t
    set (t.remote_bk_status,
        t.modify_time,
        t.local_bk_starttime,
        t.remote_bk_endtime,
        t.local_duration,
        t.total_duration,
        t.message) =
       (select remote_bk_status,
               sysdate,
               local_bk_starttime,
               remote_bk_endtime,
               local_duration,
               total_duration,
               message
          from monitor.db_backup_info b
         where b.id = '$SEQVAL')
     where id > '$SEQVAL';

commit;
exit;
EOF

fi

}






# Initiate the command string




echo "rman local backup starting" >>$RMAN_LOG_FILE

getseqval

echo "******************"$SEQVAL
SEQRESULT=`cat  $SCRIPT_DIR/getseqval.log| grep "ORA-" | wc -l`
if [ $SEQRESULT -gt 0 ];then
  echo "Get backup table SEQVAL failed, backup job abort" >> $RMAN_LOG_FILE 
  exit 1
else
  insert_title
fi

# Initiate the command string
if [ "$CUSER" = "root" ]
then
    echo "Root Command String: $RUN_STR" >> $RMAN_LOG_FILE
    su - $ORACLE_USER -c "$RUN_STR" >> $RMAN_LOG_FILE
    RSTAT=$?
else
    echo "User Command String: $RUN_STR" >> $RMAN_LOG_FILE
    /bin/sh -c "$RUN_STR" >> $RMAN_LOG_FILE
    RSTAT=$?
fi

echo "rman local backup end" >>$RMAN_LOG_FILE

update_local

echo 'get md5 value for each backuppiece if the local status is successed:' >> $RMAN_LOG_FILE

bkp_record

echo >> $RMAN_LOG_FILE 
echo Script $0 >> $RMAN_LOG_FILE 
echo ==== $MSG on `date` ==== >> $RMAN_LOG_FILE 
echo >> $RMAN_LOG_FILE 

 
if [ $LOCAL_BK_STATUS -eq 0 ];then
   upload_ftp
   remote_result

fi
exit $? 
