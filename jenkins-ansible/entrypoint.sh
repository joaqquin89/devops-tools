#!/bin/bash

export VARIABLES_FILES=$(find . -name va*.tf)

if [ VARIABLES_FILES != "" ]
then
  terraform init
  terraform plan
  terraform apply
else
    terraform init
    terraform plan -input=true
    terraform apply -input=true
fi