#cloud-config

# and the empty group cloud-users.

runcmd:
  - variable=$(ifconfig | grep -i 'inet' | grep -v '127.0.0' | awk '{print $2}' | cut -d ':' -f2 | cut -d'.' -f1,2,3 | sed '/^\s*$/d' |sed -n '2p')
  - route add default gw ${variable}."1" dev eth0
  - route del -net default gw ${variable}."11" dev eth0
  - echo 'export http_proxy=""' >>  /etc/profile.d/export.sh
  - echo 'export https_proxy=""' >>  /etc/profile.d/export.sh
  - mkdir -p /etc/systemd/system/docker.service.d
  - cd /etc/systemd/system/docker.service.d
  - echo -e '[Service]\nEnvironment="HTTP_PROXY="' >> http-proxy.conf
  - echo -e '[Service]\nEnvironment="HTTPS_PROXY="' >> https-proxy.conf
  - systemctl daemon-reload
  - systemctl restart docker 
