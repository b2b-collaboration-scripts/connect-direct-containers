#!/bin/bash
# sfgpv-and-sctk-delete.sh

printf "\n\n########## Deleting SFG Toolkit Sidecar ##########\n\n"

# Change project to B2Bi
oc project b2bi 1>>/tmp/b2bi-cluster-install.log 1>/dev/null 2>&1

# Deploy Toolkit Container
printf "Deleting Toolkit Deployment ...\n\n"
oc delete -f ~/B2Bcontainerinstall/DeploySterlingSFGOpenShift/sterlingtoolkitdeploy.yaml 1>/dev/null 2>&1

# Deploy PV-PVC Volumes
printf "Deleting PV-PVC Volumes ...\n\n"
oc delete -f ~/B2Bcontainerinstall/DeploySterlingSFGOpenShift/sterlingtoolkitpvpvc.yaml 1>/dev/null 2>&1

# Delete DB2 Project Namespace
printf "Deleting Toolkit Pod ...\n\n"

until oc get pods -n b2bi 1>/dev/null 2>/tmp/sfgpverrmsg && grep "No resources found in b2bi namespace." < /tmp/sfgpverrmsg 1>/dev/null 2>&1
do
  ((attempt=$attempt+1))
  printf "Waiting for toolkit pod to be deleted ... $attempt\n"
  sleep 2
  printf "Sleeping 2 seconds ...\n"
done

printf "\nToolkit Deployment Successfully Deleted\n"
