#!/bin/bash
# CD-ITX-Misc-install.sh

# If $NameSpace does not exist ...

if [ -z $NameSpace ]
then

  printf "\n"
  printf "  You must export the following parameter before running this script from the command line:\n\n"
  printf "    NameSpace:         The namespace prefix that was used for this cluster.\n\n"

  exit 127  # Exit and explain usage.
fi

# Validate the project namespace exists
if ! oc get namespace "$NameSpace" 1>/dev/null 2>&1
then

  printf "\n"
  printf "    The namespace: \"$NameSpace\" does not exist.\n"
  printf "    Please enter the correct namespace and try again.\n\n"

  exit 127
fi

# Make sure we're using $NameSpace project namespace
printf "\n"
printf "Now using \"$NameSpace\" namespace ...\n\n"
oc project $NameSpace 1>>/tmp/cd-itx-cluster-install.log 2>&1

# Initialize saved values file for final helm install script
>$INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/3-CD-ITX-Misc-install/3-savedvalues

# Retrieve Saved Values
. $INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/install-CD-ITX-Cluster.savedvalues

# Set basic Pod security and Cluster adminstration prerequisites
printf "Setting cluster security prerequisites ...\n\n"

# Set up basic cluster security prerequisites and namespace prerequisites
printf "Setting cluster administration security prerequisites ...\n\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1
cd $INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/ibm_cloud_pak/pak_extensions/pre-install/clusterAdministration/
chmod 755 ./createSecurityClusterPrereqs.sh
./createSecurityClusterPrereqs.sh 1>>/tmp/cd-itx-cluster-install.log 2>&1

# Set up basic cluster security requisites
printf "Setting namespace security prerequisites ...\n\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1
cd $INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/ibm_cloud_pak/pak_extensions/pre-install/namespaceAdministration/
chmod 755 ./createSecurityNamespacePrereqs.sh
./createSecurityNamespacePrereqs.sh $NameSpace 1>>/tmp/cd-itx-cluster-install.log 2>&1

# Base 64 encode passwords -and-
# Create Connect:Direct password secrets yaml

printf "\n########## Installing Secrets ##########\n\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1

echo \
"# CD-ITX Password Secrets File - cdpaswordsecrets.yaml
# Date:       `date`
# NameSpace:  $NameSpace

---
apiVersion: v1
kind: Secret
metadata:
  name: cd-password-secrets
type: Opaque
data:
  admPwd: $(echo -n 'newpass' | base64)
  appUserPwd: $(echo -n 'newpass' | base64)
  crtPwd: $(cat $INSTALL_BASE_DIR/secure-plus-cert-passphrase | base64)
  keyPwd: $(cat $INSTALL_BASE_DIR/secure-plus-cert-passphrase | base64)
">$INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/cdpaswordsecrets.yaml

# Create CD-ITX password secrets
printf "Creating Password Secrets ...\n"
oc create -f $INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/cdpaswordsecrets.yaml 1>>/tmp/cd-itx-cluster-install.log 2>&1

exit 0