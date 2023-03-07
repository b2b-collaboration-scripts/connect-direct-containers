#!/bin/bash
# 2-install-CD-ITX-Cluster.sh

# Get administrator's email address, release name, namespace, Ingress Subdomain, IBM Entitlement key, CD Helm chart version and ITX Helm chart version from command line
# Script must be invoked with 7 command-line args

# Begin CD-ITX installation ...
printf "\n"
printf "Begin CD-ITX installation ...\n"
printf "Validating command line arguments ...\n\n"

if [ $# -ne 7 ]
then

  printf "\n"
  printf "  Usage:\n    `basename $0` EmailAddress YourReleaseName NameSpace IngressSubdomain IBM-Entitlement-Key-File CD-Helm-Chart ITX-Helm-Chart\n\n"
  printf "    You must provide the following parameters:\n\n"
  printf "    AdminEmailAddress:        Email address of the cluster administrator.\n"
  printf "    ReleaseName:              Name of the release for this cluster install.\n"
  printf "    NameSpace:                A unique namespace prefix for the resources that will be created for this cluster.\n"
  printf "    IngressSubDomain:         Cluster ingress sub-domain.\n"
  printf "    IBM-Entitlement-Key-File: Full path to a file containing your entitlement key.\n"
  printf "    CD Helm Chart Version:    Helm chart name\/version to install.\n"
  printf "    ITX Helm Chart Version:   Helm chart name\/version to install.\n\n"

  exit 127  # Exit and explain usage.
fi

# Set up email address for yaml file
export AdminEmailAddress="$1"

# Basic email address validation
if ! [[ "$AdminEmailAddress" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$ ]]
then

  printf "\n"
  printf "    The email address you entered is not valid.\n"
  printf "    Please enter a valid email address and try again.\n\n"

  exit 127
fi

# Strip any whitespace from the release name
export ReleaseName=`echo "$2"|perl -p -e 's/\s+//g'`

# Check for any "illegal" characters in release name
# if ! [[ "$ReleaseName" =~ ^[a-z0-9-]$ ]] # Fix this one day ...

if ! (perl -e '"$ENV{ReleaseName}" =~ m/^[a-z\-\d]+$/ ? exit 0 : exit 1')
then

  printf "\n"
  printf "    The release name may only contain lowercase letters, numbers and the dash character \"-\".\n"
  printf "    Please correct the release name and try again.\n\n"

  exit 127
fi

# Strip any whitespace from the namespace
export NameSpace=`echo "$3"|perl -p -e 's/\s+//g'`

# Check for any "illegal" characters in namespace
# if ! [[ "$NameSpace" =~ ^[a-z0-9]$ ]] - Fix this one day ...

if ! (perl -e '"$ENV{NameSpace}" =~ m/^[a-z\d]+$/ ? exit 0 : exit 1')
then

  printf "\n"
  printf "    A namespace may only contain lowercase letters and numbers.\n"
  printf "    Please correct the namespace and try again.\n\n"

  exit 127
fi

# Validate the project namespace is not in use already
if oc get namespace "$NameSpace" 1>/dev/null 2>&1
then

  printf "\n"
  printf "    The namespace you entered: \"$NameSpace\" is already being used.\n"
  printf "    Please choose a different namespace for this installation and try again.\n\n"

  exit 127
fi

# Strip any whitespace from the ingress subdomain
export IngressSubDomain=`echo "$4"|perl -p -e 's/\s+//g'`

# Check to see if the domain can be reached.  Ping 'should' be sufficient for this test.
printf "\nNow checking to see if ingress subdomain exists ... \n"
ping -c 5 "$IngressSubDomain" 1>/dev/null 2>&1

# If ping errors out there may be a problem with the sub domain provided
if [ $? -ne 0 ]
then

  printf "\n"
  printf "    The ingress subdomain supplied cannot be reached.\n"
  printf "    Please verify the ingress subdomain and try again.\n\n"

  exit 127
fi

# Set default entitlement key filename
export EntitlementKeyFileName="$5"

# Check for the option entitlement key filename command line option
if ! [ -e "$5" ]
then

  printf "\n"
  printf "    The entitlement key filename you provided does not exist.\n"
  printf "    Please verify the location of the file and try again.\n\n"
  exit 127
fi

# Set installation base directory if not already set
if [ -z $INSTALL_BASE_DIR ]
then

  export INSTALL_BASE_DIR=`pwd`
fi

# Prepare directory for Helm charts
/bin/rm -rf $INSTALL_BASE_DIR/CD-ITX-Containers 1>/dev/null 2>&1
mkdir -p $INSTALL_BASE_DIR/CD-ITX-Containers 1>/dev/null 2>&1

# Validate CD Helm chart name
export CDHelmChartName="$6"

# Download CD Helm chart
if ! $(wget https://github.com/IBM/charts/raw/master/repo/ibm-helm/$6.tgz)
then

  printf "\n"
  printf "    The Connect Direct Helm chart name you provided does not exist.\n"
  printf "    Please verify the Helm chart name and try again.\n\n"
  exit 127
else

  mv $6.tgz $INSTALL_BASE_DIR/CD-ITX-Containers
  cd $INSTALL_BASE_DIR/CD-ITX-Containers; tar xvzf $6.tgz
fi

# Validate ITX Helm chart name
export ITXHelmChartName="$7"

# Download ITX Helm chart
if ! $(wget https://github.com/IBM/charts/raw/master/repo/ibm-helm/$7.tgz)
then

  printf "\n"
  printf "    The ITX Helm chart name you provided does not exist.\n"
  printf "    Please verify the Helm chart name and try again.\n\n"
  exit 127
else

  mv $7.tgz $INSTALL_BASE_DIR/CD-ITX-Containers
  cd $INSTALL_BASE_DIR/CD-ITX-Containers;tar xvzf $7.tgz
fi

# Check for helm installation
if ! helm 1>/dev/null 2>&1
then

  printf "\n"
  printf "    Now installing \'helm\' ...\n"
  printf "\n"

  # Install helm
  sudo curl -L https://mirror.openshift.com/pub/openshift-v4/clients/helm/latest/helm-linux-amd64 -o /usr/local/bin/helm

  cd /usr/local/bin

  sudo chmod 755 helm

  cd $INSTALL_BASE_DIR
fi

# Generate Connect Direct Secure Plus Certificate
#if ! $(openssl genrsa -des3 -passout file:$INSTALL_BASE_DIR/secure-plus-cert-passphrase -out privkey.pem 2048 1>>/tmp/cd-itx-cluster-install.log 2>&1 \
#       && openssl rsa -in ./privkey.pem -passin file:$INSTALL_BASE_DIR/secure-plus-cert-passphrase -outform PEM -pubout -out public.pem 1>>/tmp/cd-itx-cluster-install.log 2>&1)
#then

#  printf "\n"
#  printf "    CRITICAL ERROR!"
#  printf "    Could not generate Connect:Direct Secure Plus certificate\n"
#  printf "    Error with openssl command.>\n\n"
#  exit 127
#fi

# Initialize install log file
>/tmp/cd-itx-cluster-install.log

# Initialize saved values file for final helm install script
>$INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/install-CD-ITX-Cluster.savedvalues

# Begin cluster installation
printf "########## Installing CD-ITX Cluster - Release Name: $ReleaseName ##########\n\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1
printf "Begin cluster install: `date`\n\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1
printf "INSTALL_BASE_DIR:      $INSTALL_BASE_DIR\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1
printf "Admin Email Address:   $AdminEmailAddress\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1
printf "Release Name:          $ReleaseName\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1
printf "NameSpace:             $NameSpace\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1
printf "IngressSubDomain:      $IngressSubDomain\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1
printf "Key FileName:          $EntitlementKeyFileName\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1
printf "CD Helm Chart Name:    $CDHelmChartName\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1
printf "ITX Helm Chart Name:   $ITXHelmChartName\n\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1

# Write command line parameters to saved values file
printf 'INSTALL_BASE_DIR='"\"$INSTALL_BASE_DIR\"\n" >>$INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/install-CD-ITX-Cluster.savedvalues
printf 'AdminEmailAddress='"\"$AdminEmailAddress\"\n" >>$INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/install-CD-ITX-Cluster.savedvalues
printf 'ReleaseName='"\"$ReleaseName\"\n" >>$INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/install-CD-ITX-Cluster.savedvalues
printf 'NameSpace='"\"$NameSpace\"\n" >>$INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/install-CD-ITX-Cluster.savedvalues
printf 'IngressSubDomain='"\"$IngressSubDomain\"\n" >>$INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/install-CD-ITX-Cluster.savedvalues
printf 'EntitlementKeyFileName='"\"$EntitlementKeyFileName\"\n" >>$INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/install-CD-ITX-Cluster.savedvalues
printf 'CDHelmChartName='"\"$CDHelmChartName\"\n" >>$INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/install-CD-ITX-Cluster.savedvalues
printf 'ITXHelmChartName='"\"$ITXHelmChartName\"\n" >>$INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/install-CD-ITX-Cluster.savedvalues

# Create a cluster project/namespace
printf "Creating Project Namespace ...\n\n"
oc new-project "$NameSpace" 1>>/tmp/cd-itx-cluster-install.log 2>&1

# Generate Connect Direct Secure Plus Certificate

cd $INSTALL_BASE_DIR

if ! $(openssl genrsa -des3 -passout file:$INSTALL_BASE_DIR/secure-plus-cert-passphrase -out privkey.pem 2048 1>>/tmp/cd-itx-cluster-install.log 2>&1 \
       && openssl rsa -in ./privkey.pem -passin file:$INSTALL_BASE_DIR/secure-plus-cert-passphrase -outform PEM -pubout -out public.pem 1>>/tmp/cd-itx-cluster-install.log 2>&1)
then

  printf "\n"
  printf "    CRITICAL ERROR!"
  printf "    Could not generate Connect:Direct Secure Plus certificate\n"
  printf "    Error with openssl command.>\n\n"
  exit 127
fi

# Create CD-ITX certificate secrets with Secure Plus certs
printf "Creating Certificate Secrets ...\n"
oc create secret generic cd-cert-secret --from-file=certificate_file1=$INSTALL_BASE_DIR/pubkey.pem --from-file=certificate_file2=$INSTALL_BASE_DIR/privkey.pem 1>>/tmp/cd-itx-cluster-install.log 2>&1

# Install entitlement key

export EntitlementKey=`cat $EntitlementKeyFileName`

# Create-IBM-Entitlement-Secret.sh projectnamespace entitlement-key-file
$INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/tools/entitlement/Create-IBM-Entitlement-Secret.sh "$NameSpace" "$EntitlementKey" 1>>/tmp/cd-itx-cluster-install.log 2>&1

# Run install scripts

# Miscellaneous Install - Setup
printf "\nInstall Miscellaneous Pre-Reqs: `date`\n\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1
$INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/3-CD-ITX-Misc-install/CD-ITX-Misc-install.sh

# Miscellaneous Setup
printf "\nInstall SCC's and PV-PVC: `date`\n\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1
$INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/5-CD-ITX-PVPVC-install/CD-ITX-PVPVC-install.sh

# Run helm install process
printf "\nBegin helm install: `date`\n\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1
$INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/6-helm-install/helm-install.sh

exit $?