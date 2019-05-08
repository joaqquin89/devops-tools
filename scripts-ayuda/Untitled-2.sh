#!/bin/bash

function DELETE_UNUSED_VERSIONS
{
  all_versions=$(aws --region $2 elasticbeanstalk describe-application-versions --application-name $1 | jq -r ' .ApplicationVersions | .[].VersionLabel ')
  read -a ARRAY <<< $all_versions

  used=$(aws --region $2 elasticbeanstalk describe-environments --application-name $1 |jq -r  ' .Environments | .[].VersionLabel')
  read -a TO_REMOVE <<< $used

    for pkg in "${ARRAY[@]}"; do
        for remove in "${TO_REMOVE[@]}"; do
            KEEP=true
            if [[ ${pkg} == ${remove} ]]; then
                KEEP=false
                break
            fi
        done
        if ${KEEP}; then
        aws --region $2  elasticbeanstalk delete-application-version --application-name $1 --version-label $pkg
        fi
    done
}

for REGION in "us-east-1" "us-east-2"
do
    LENGTH_REPOSITORY=$(aws --region ${REGION} elasticbeanstalk describe-applications | jq -r '.Applications | length' )
    for (( i=0; i<=$LENGTH_REPOSITORY; i++ ))
    do
        export i;
        APP_NAME=$( aws --region ${REGION} elasticbeanstalk describe-applications  | jq -r '.Applications['$i'].ApplicationName' )
        DELETE_UNUSED_VERSIONS ${APP_NAME} ${REGION}
        sleep 2
    done
done