#!/bin/bash -eux

HOST=$(hostname)
DATE=$(date +%Y%m%d)


#####deshabilitamos servicios innecesarios

yum remove xinetd -y
yum remove telnet-server -y
yum remove rsh-server -y
yum remove telnet -y
yum remove rsh-server -y
yum remove nfs-utils -y
yum remove rsh -y
yum remove ypbind -y
yum remove ypserv -y
yum remove tftp-server -y
#yum remove cronie-anacron -y
yum remove bind -y
yum remove oddjob -y
yum remove portmap -y
yum remove vsftpd -y
yum remove httpd -y
yum remove dovecot -y
yum remove squid -y
yum remove net-snmpd -y
yum remove smartmontools -y

service  xinetd stop
service  rexec stop
service  rsh stop
service  rlogin stop
service  ypbind stop
service  tftp stop
service  certmonger stop
service  cgconfig stop
service  cgred stop
service  cpuspeed stop
service  irqbalance start
service  kdump stop
service  mdmonitor stop
service  messagebus stop
service  netconsole stop
service  oddjobd stop
service  portreserve stop
service  psacct start
service  qpidd stop
service  rdisc stop
service  rhnsd stop
service  rhsmcertd stop
service  saslauthd stop
service  smartd stop
service  sysstat stop
#service  crond stop
service  atd stop
service  nfslock stop
service  named stop
service  httpd stop
service  dovecot stop
service  squid stop
service  snmpd stop
service  rpcgssd stop
service  rpcsvcgssd stop
service  rpcidmapd stop
service  netfs stop
service  nfs stop
service  avahi-daemon stop
service  cups stop
service  dhcpd stop
service  iptables stop
chkconfig iptables off

###AJUSTES SSH

echo "PermitRootLogin no" >> /etc/ssh/sshd_config
sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
#sed -i 's/#IgnoreRhosts yes/IgnoreRhosts yes/g' /etc/ssh/sshd_config
#sed -i 's/#ClientAliveInterval [0-9]/ClientAliveInterval 500/g' /etc/ssh/sshd_config
#sed -i 's/#ClientAliveCountMax [0-9]/ClientAliveCountMax 3/g' /etc/ssh/sshd_config
#sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/g' /etc/ssh/sshd_config

###deshabilitamos protocolos poco comunes##

echo "install dccp /bin/false" > /etc/modprobe.d/dccp.conf
echo "install sctp /bin/false" > /etc/modprobe.d/sctp.conf
echo "install rds /bin/false" > /etc/modprobe.d/rds.conf
echo "install tipc /bin/false" > /etc/modprobe.d/tipc.conf

######deshabilitamos usuarios no usados##

echo "Idle users will be removed after 15 minutes"
echo "readonly TMOUT=900" >> /etc/profile.d/os-security.sh
echo "readonly HISTFILE" >> /etc/profile.d/os-security.sh
chmod +x /etc/profile.d/os-security.sh

##bof mitigacion

echo "NOZEROCONF=yes" >> /etc/sysconfig/network

echo "options ipv6 = 1 " >> /etc/modprobe.d/d.conf

echo "kernel.exec-shield = 1" >> /etc/sysctl.conf
echo "kernel.randomize_va_space = 2" >> /etc/sysctl.conf

################################
########CONFIGURE IPV4##########
################################

touch /etc/sysctl.d/10-network-security.conf

# Ignore ICMP broadcast requests
echo "net.ipv4.icmp_echo_ignore_broadcasts = 1" >> /etc/sysctl.d/10-network-security.conf
echo "net.ipv4.conf.default.rp_filter=1" >> /etc/sysctl.d/10-network-security.conf
echo "net.ipv4.conf.all.rp_filter=1" >> /etc/sysctl.d/10-network-security.conf
#  source packet routing
echo "net.ipv4.conf.all.accept_source_route = 0" >> /etc/sysctl.d/10-network-security.conf
echo "net.ipv6.conf.all.accept_source_route = 0" >> /etc/sysctl.d/10-network-security.conf
echo "net.ipv4.conf.default.accept_source_route = 0" >> /etc/sysctl.d/10-network-security.conf
echo "net.ipv6.conf.default.accept_source_route = 0" >> /etc/sysctl.d/10-network-security.conf
# Ignore send redirects
echo "net.ipv4.conf.all.send_redirects = 0" >> /etc/sysctl.d/10-network-security.conf
echo "net.ipv4.conf.default.send_redirects = 0" >> /etc/sysctl.d/10-network-security.conf
echo "net.ipv4.tcp_syncookies=1" >> /etc/sysctl.d/10-network-security.conf
# Block SYN attacks
echo "net.ipv4.tcp_max_syn_backlog = 2048" >> /etc/sysctl.d/10-network-security.conf
echo "net.ipv4.tcp_synack_retries = 2" >> /etc/sysctl.d/10-network-security.conf
echo "net.ipv4.tcp_syn_retries = 5" >> /etc/sysctl.d/10-network-security.conf

# Log Martians
echo "net.ipv4.conf.all.log_martians = 1" >> /etc/sysctl.d/10-network-security.conf
echo "net.ipv4.icmp_ignore_bogus_error_responses = 1" >> /etc/sysctl.d/10-network-security.conf

# Ignore ICMP redirects
echo "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.d/10-network-security.conf
echo "net.ipv6.conf.all.accept_redirects = 0" >> /etc/sysctl.d/10-network-security.conf
echo "net.ipv4.conf.default.accept_redirects = 0" >> /etc/sysctl.d/10-network-security.conf
echo "net.ipv6.conf.default.accept_redirects = 0" >> /etc/sysctl.d/10-network-security.conf
service procps start

# Disable ipv6 Service
echo "net.ipv6.conf.all._ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default._ipv6 = 1" >> /etc/sysctl.conf

###auditamos el sistema operativo
git clone https://github.com/CISOfy/lynis

cd lynis
./lynis -c -Q

curl -X PUT -T /var/log/lynis.log  -H "x-ms-date: $(date -u)" -H "x-ms-blob-type: BlockBlob" "https://buffetcloudcore.blob.core.windows.net/packer-logs/${HOST}.${DATE}-Auditorialynis.log?sv=2017-07-29&ss=bfqt&srt=sco&sp=rwdlacup&se=2018-12-31T05:16:14Z&st=2018-03-13T21:16:14Z&spr=https&sig=nzF%2FSY9HU3KqL672J9575FK8%2F2ZFK2uqkdM4aAClBio%3D"
cd ..
rm -rf lynis


echo All finished! Rebooting...
(sleep 5; reboot) &
