#!/bin/bash 
# Create-IBM_Entitlement-Secret.sh
# Create IBM Entitlement Secret Key for cluster installation

printf "\nNow creating IBM Entitlement Key for: $1\n"
printf "\nEntitlement key contents:             $2\n"

oc new-project "$1" 1>/dev/null 2>&1 || true

oc create secret docker-registry ibm-entitlement-key -n "$1" \
--docker-username=cp \
--docker-password="$2" \
--docker-server=cp.icr.io