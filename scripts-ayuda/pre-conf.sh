#!/bin/bash
#===================================================================================
# FILE:         pre-conf.sh
#
# DESCRIPTION:  Configurar Base de datos
#
# OPTIONS:      Configuracion en Documentancion interna
# REQUIREMENTS: ---
# BUGS:         ---
# NOTES:        ---
# AUTHOR:       Joaquin Jachura
# MANTENCION:   Joaquin Jachura <jjachurac@falabella.cl>
# COMPANY:      ADESSA
# VERSION:      1.0
#===================================================================================

# ================== Variables =====================================================

FECHA=`date +'%d/%m/%Y %H:%M'`
FECHA_DAT=`date +'%d%m%Y%H%M'`

# ================== DECONFIGURACION DE BASE DE DATOS ==================
printf "Deconfiguracion Base De Datos" >> /root/INIT.txt
/u01/home/app/grid/11.2.0.3/grid/crs/install/rootcrs.pl -deconfig -force
/u01/home/app/grid/11.2.0.3/grid/root.sh
/u01/home/app/oracle/product/11.2.0.3/db/root.sh

# ==================  CONFIGURAR DISCO CON FDISK ================== 


printf "Configuracion FDSISK " >> /root/INIT.txt
fdisk -l |grep /dev/ |grep -v mapper |grep -v Linux | grep -v ram* |awk -F":" '{print $1}' > /tmp/disk2.out
disk_asm=`cat /tmp/disk2.out |tail -1 |awk '{print $2}'`
fdisk ${disk_asm}<<EOF
 n
 p
 1
 2
 
 w
EOF
oracleasm init
oracleasm createdisk DBF_DATA "${disk_asm}1"

# ================== CONFIGURACIONES DE SERVICIOIS CSS Y LISTENER=======
su - oracle -c '. +ASM; crsctl modify resource "ora.cssd" -attr "AUTO_START=1" '
su - oracle -c '. +ASM; crsctl modify resource "ora.diskmon" -attr "AUTO_START=1" '
su - oracle -c '. +ASM; crsctl start resource "ora.cssd" '

echo "subir listener"
su - oracle -c ". +ASM;  srvctl add listener -l LISTENER -p 'TCP:1541,/IPC:EXTPROC1541' "
su - oracle -c '. +ASM;  srvctl setenv listener -T "ORACLE_BASE=$ORACLE_BASE" '

# ================= CONFIGURAR ASM ==================

su - oracle -c ". +ASM; srvctl add asm -l LISTENER -d '/dev/oracleasm/disks/*' -p $ORACLE_HOME/dbs/spfile+ASM.ora"
su - oracle -c '. +ASM; srvctl setenv asm -T "ORACLE_BASE=$ORACLE_BASE" '
su - oracle -c '. +ASM; crsctl start resource -all'

su - oracle -c " . +ASM; sqlplus / as sysasm << EOF
    create diskgroup DBF_DATA external redundancy disk '/dev/oracleasm/disks/DBF_DATA' name DBF_DATA attribute 'COMPATIBLE.ASM'='11.2';
	!asmcmd lsdg;
	exit;
EOF"

# ================= CONFIGURAR PFILE ==================

cat > /u01/home/app/oracle/product/11.2.0.3/db/dbs/initqasots.ora <<EOF
*.audit_file_dest='/u01/home/app/oracle/obase/admin/qasots/adump'
*.audit_trail='db'
*.compatible='11.2.0.0.0'
*.control_files='+DBF_DATA/qasots/control01.ctl','+DBF_DATA/qasots/control02.ctl'
*.db_block_size=16384
*.db_domain=''
*.db_name='qasots'
*.diagnostic_dest='/u01/home/app/oracle/obase'
*.dispatchers='(PROTOCOL=TCP) (SERVICE=qasotsXDB)'
*.open_cursors=300
*.pga_aggregate_target=1091567616
*.processes=500
*.remote_login_passwordfile='EXCLUSIVE'
*.sessions=555
*.sga_target=3276800000
*.undo_tablespace='UNDOTBS1'
EOF

# ================== RECOVERY DE LA BASE DE DATOS ==================
su - oracle -c ". qasots;\n
rman target / << EOF
shutdown immediate;
startup nomount;
restore controlfile from '/u01/bkp/ctl_02ta08fp_1_1.bkp';
startup mount;
catalog start with '/u01/bkp';
YES
crosscheck backup;
restore database;
alter database open resetlogs;
EOF"

# ================== SUBIR BD==================

su - oracle -c '. qasots; srvctl add database -d qasots -o /u01/home/app/oracle/product/11.2.0.3/db'
su - oracle -c '. qasots; srvctl start database -d qasots'