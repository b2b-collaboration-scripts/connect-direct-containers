#!/bin/bash

#
# You need to run this script for each namespace.
#
# This script takes one argument; the namespace where the chart was installed.
#
# Example:
#     ./deleteSecurityNamespacePrereqs.sh myNamespace
#

if [ "$#" -lt 1 ]; then
	echo "Usage: deleteSecurityNamespacePrereqs.sh NAMESPACE"
  exit 1
fi

namespace=$1

[[ $(dirname $0 | cut -c1) = '/' ]] && scriptDir=$(dirname $0)/ || scriptDir=$(pwd)/$(dirname $0)/

cd ${scriptDir}
source ../../common/kubhelper.sh

isApplied="false"
kubectl get namespace $namespace &> /dev/null
if [ $? -ne 0 ]; then 
    echo "ERROR: Namespace $namespace does not exist."
    exit 1
fi

if supports_scc; then
    echo "Removing all namespace users from SecurityContextConstraints"
    if command -v oc >/dev/null 2>&1 ; then
        # Note: this script only works on OpenShift >= 3.11, otherwise you must run the following command manually
        oc adm policy remove-scc-from-group ibm-connect-direct-scc system:serviceaccounts:$namespace
    else
        echo "ERROR:  The OpenShift CLI is not available..."
    fi
    isApplied="true"
fi

if supports_psp; then
    if [ "$isApplied" == "false" ]; then
       # Replace the NAMESPACE tag with the namespace specified in a temporary yaml file.
       sed 's/{{ NAMESPACE }}/'$namespace'/g' ../../pre-install/namespaceAdministration/ibm-cdu-rb.yaml > $namespace-ibm-cdu-rb.yaml

       # Delete the role binding for all service accounts in the current namespace
       kubectl delete -f $namespace-ibm-cdu-rb.yaml -n $namespace

       # Clean up - delete the temporary yaml file.
       rm $namespace-ibm-cdu-rb.yaml
    fi
fi
