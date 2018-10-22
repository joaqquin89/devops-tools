#!/bin/bash
#===================================================================================
# FILE:         lvm-up.sh
#
# DESCRIPTION:  Crea Estructura LVM
#
# OPTIONS:      Configuracion en Documentancion interna
# AUTHOR:       Joaquin Jachura
# MANTENCION:   Joaquin Jachura <jjachurac@falabella.cl>
# COMPANY:      ADESSA
# VERSION:      1.0
#===================================================================================
FECHA=`date +'%d/%m/%Y %H:%M'`
FECHA_DAT=`date +'%d%m%Y%H%M'`
# ================== RECONFIGURACION DE TABLA HOSTS ==================
IP=` ifconfig | grep -i 'inet' | grep -v '127.0.0' | awk '{print $2}' | cut -d':' -f2 | sed -n '1p' `;
HOST=`hostname`
printf "${IP} ${HOST} \n" >> /etc/hosts
echo "${IP} ${HOST} \n"
#======================== LEVANTAR LVM ================================================
fdisk -l |grep /dev/ |grep -v mapper |grep -v Linux | grep -v ram* | head -2 |awk -F":" '{ print $1}'>/tmp/disk.out
disks_count=`fdisk -l |grep /dev/ |grep -v mapper |grep -v Linux | grep -v ram* |awk -F":" '{ print $1}'|wc -l`
disk_lvm=`cat /tmp/disk.out |tail -1 | awk '{print $2}'`
size=`fdisk -l ${disk_lvm}| grep Disk |grep -v identifier |awk  '{print $3}'`
pvcreate ${disk_lvm}
vgcreate vgdat01 ${disk_lvm}

if [ "${disks_count}" -ge 3 ]; then
        mkdir -p /u01 /u80 /u03 /u81 /dumps
        echo "CREACION DE LVM"
        # ================== CREACION DE LVM ==================
        lvcreate -n lvdat01 -L  80G vgdat01
        lvcreate -n lvdat02 -L  50G vgdat01
        lvcreate -n lvdat03 -L  50G vgdat01
        lvcreate -n lvdat04 -L  40G vgdat01
        lvcreate -n lvdat05 -L  80G vgdat01

        # ================== FORMAT DE LOS LVDAT =============
        mkfs.ext4 /dev/vgdat01/lvdat01
        mkfs.ext4 /dev/vgdat01/lvdat02
        mkfs.ext4 /dev/vgdat01/lvdat03
        mkfs.ext4 /dev/vgdat01/lvdat04
        mkfs.ext4 /dev/vgdat01/lvdat05

        # ================== AÑADIR AL FSTAB ==================
        printf "/dev/vgdat01/lvdat01    /u01                    ext4    defaults        1 0 \n" >> /etc/fstab
        printf "/dev/vgdat01/lvdat02    /u80                    ext4    defaults        1 0 \n" >> /etc/fstab
        printf "/dev/vgdat01/lvdat03    /u81                    ext4    defaults        1 0 \n" >> /etc/fstab
        printf "/dev/vgdat01/lvdat04    /dumps                  ext4    defaults        1 0 \n" >> /etc/fstab
        printf "/dev/vgdat01/lvdat05    /u03                    ext4    defaults        1 0 \n" >> /etc/fstab

        mount -a

        printf "Inicio configuraciones" >> /root/INIT.txt
        cd /home/oracle
        printf "mover a /u01 los .tar" >> /root/INIT.txt
        mv u01-inst.tar bkp.tar /u01
        printf "acceso a /u01" >> /root/INIT.txt
        cd /u01
        ls -l  >> /root/INIT.txt
        printf "descomprimir " >> /root/INIT.txt
        tar -xf u01-inst.tar
        tar -xvf bkp.tar
        ls -l  >> /root/INIT.txt
        printf "eliminar archivos" >> /root/INIT.txt
        rm -f u01-inst.tar bkp.tar
        ls -l  >> /root/INIT.txt
fi 