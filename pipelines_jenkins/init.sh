#!/bin/sh

######################################
## DEFINICION DE USER Y PASS
######################################
export privatePass=$(curl \
    -H "X-Vault-Token: 1AUVxmUJCOymfo4WKmOZfBl7" \
    -X GET \
   http://10.246.36.221:8200/v1/secret/web/pass-token | sed 's/\\\\\//\//g' | sed 's/[{}]//g'  | awk -v k="password" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' \
   | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w "password"| cut -d":" -f2| sed -e 's/^ *//g' -e 's/ *$//g' | cut -d"|" -f3 )

export privateUser=$(curl \
    -H "X-Vault-Token: 1AUVxmUJCOymfo4WKmOZfBl7" \
    -X GET \
   http://10.246.36.221:8200/v1/secret/web/user-pipeline | sed 's/\\\\\//\//g' | sed 's/[{}]//g'  | awk -v k="password" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' \
   | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w "password"| cut -d":" -f2| sed -e 's/^ *//g' -e 's/ *$//g' | cut -d"|" -f3)

###DEINICION DE JOB A EJECUTAR
JenkinsJob="ansible-nutanix-server"

###IP DE LA MAQUINA
IP=$(ifconfig eth0 | grep -i 'inet*' | grep -v '127.0.0' | awk '{print $2}'| cut -d ':' -f2 | awk 'FNR == 1')
PLAYBOOK_TYPE="playbook-provisioner.yaml"
USER="root"
CRUMB=$(curl -s 'http://'${privateUser}':'${privatePass}'@besptest.falabella.net/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)')
curl -X POST -H "$CRUMB" -u ${privateUser}:${privatePass} "http://besptest.falabella.net/job/${JenkinsJob}/buildWithParameters?IP=${IP}&PLAYBOOK=${PLAYBOOK_TYPE}&USER=${USER}"


unset privateUser
unset privatePass