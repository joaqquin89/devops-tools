#!/bin/bash

function DESCRIBE_REPOSITORY
{
        c=4
        i=4
        while [ true ]
        do
            export c;
            #Get any images
            AUX=$(aws --profile "default" --region ${2} ecr describe-images --repository-name ${1} --query \
                'sort_by(imageDetails,& imagePushedAt)[-'${c}']' | jq '.imageDigest' | tr -d '"')
            if [ ${AUX} != "null" ]
            then
                #aws --profile "default" --region ${2} ecr describe-images --repository-name ${1} --image-ids imageDigest=${AUX}
                echo "El ID DE IMAGEN ES ${AUX} y el contador ${i}"
                aws --profile "default" --region ${2} ecr batch-delete-image --repository-name ${1} --image-ids imageDigest=${AUX}
                i=`expr $i + 1`;
            else
                break;
            fi
        done
}

for REGION in "us-east-1" "us-east-2"
do
    LENGTH_REPOSITORY=$(aws --profile "default" --region ${REGION} ecr describe-repositories | jq '.repositories | length')
    for (( i=0; i<=$LENGTH_REPOSITORY; i++ ))
    do
        export i;
        #Get any images
        REPO_NAME=$(aws ecr --profile "default" --region ${REGION} describe-repositories | jq '.repositories['${i}'].repositoryName' | tr -d '"')
        echo "${REPO_NAME} en lA REGION ${REGION}"
        DESCRIBE_REPOSITORY ${REPO_NAME} ${REGION}
        sleep 2
    done
done