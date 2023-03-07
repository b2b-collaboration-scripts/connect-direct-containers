#!/bin/bash
# helm-install.sh

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

# Retrieve saved information for final yaml file build
printf "\n\nRetrieve Saved information for final yaml file build ...\n\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1

# Retrieve saved command line parameters
. $INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/install-CD-ITX-Cluster.savedvalues
. $INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/3-CD-ITX-Misc-install/3-savedvalues
. $INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/5-CD-ITX-PVPVC-install/5-savedvalues

# Initialize override.yaml file
>$INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/override.yaml
printf "# CD-ITX Cluster Install - override.yaml\n" >>$INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/override.yaml
printf "# Date:       `date`\n" >>$INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/override.yaml
printf "# Release:    $ReleaseName\n" >>$INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/override.yaml
printf "# NameSpace:  $NameSpace\n" >>$INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/override.yaml

# Build override.yaml file
while IFS='' read -r line || [[ -n "${line}" ]];
do

  # Using '^' as a search delimiter in sed rather than '/' to avoid errors due to paths that contain the slash character

  echo "$line" | grep "NAMESPACE" && line=$(echo "$line" | sed "s/NAMESPACE/$NameSpace/g")

  echo "$line" | grep "INGRESSSUBDOMAIN" && line=$(echo "$line" | sed "s/INGRESSSUBDOMAIN/$IngressSubDomain/g")

  echo "$line" >> $INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/override.yaml;

done <<EOF

license: true
# Specify the license edition as per license agreement. Valid value is prod or non-prod for Production and 
# Non-production respectively. Remember that this parameter is crucial for IBM Licensing and Metering Service
licenseType: 'prod'

# Specify the respective Docker Image details for IBMCCS
image:
  imageSecrets: 'ibm-entitlement-key'

# Specify these fields to provide config values for C:D application  
cdArgs:
  # Specify the certificate name to be used for Secure+ configuration
  crtName: 'privkey.pem'

# Specify these fields for C:D admin user cduser
cduser:
  # Specify this to set a UID for the cduser. This is also equivalent to runAsUser security context.
  uid: 1000
  # Specify this to set a GID for the cduser. This is also equivalent to runAsGroup security context.
  gid: 1000

storageSecurity:
  fsGroup: 1000
  supplementalGroups: [5555]

# persistence section specifies persistence settings which apply to the whole chart
persistence:
  # enabled is whether to use Persistent Volumes or not
  enabled: true
  # useDynamicProvisioning is whether or not to use Storage Classes to dynamically create Persistent Volumes 
  useDynamicProvisioning: false

# Specify these fields for Persistence Volume Claim details
pvClaim:
  # Specify the existing PV claim name to be used for deployment
  existingClaimName: 'NAMESPACE-cditxpvc'
  # Specify this to use any Storage Class for PVC
  storageClassName: 'ibmc-file-gold'
  accessMode: 'ReadWriteOnce'
  selector:
    # Specify this to use selector label name for PV-PVC bind
    label: ''
    # Specify this to use selector label value for PV-PVC bind
    value: ''
  size: 20Gi

# Specify the Secret configuration for C:D
secret:
  # Secret name for configuring passwords for C:D
  secretName: 'cd-password-secrets'
  # Secret name of secure plus certificates and LDAP certificates, only needed if Dyanamic Provisioining is Enabled
  certSecretName: "cd-cert-secrets"

# Specify the service account details
serviceAccount:
  # Set this field to 'true' to create service account or 'false' to use existing service account
  create: false
  # Specify the name of service account to be used 
  name: 'NAMESPACE-cd-itx'

# liveness and Probeness details for the health of pods
livenessProbe:
  initialDelaySeconds: 240
  timeoutSeconds: 60
  periodSeconds: 240

readinessProbe:
  initialDelaySeconds: 240
  timeoutSeconds: 60
  periodSeconds: 240
EOF

# Run helm install command
printf "Installing CD-ITX - Running helm ...\n"

# helm install
helm install "$ReleaseName" --namespace "$NameSpace" --timeout 240m0s -f $INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/override.yaml $INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/ 1>>/tmp/cd-itx-cluster-install.log 2>&1

#EXIT_CODE=$?

# helm install --dry-run to test yaml combining

printf "\nHelm install completed at: `date`\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1
printf "\nExit status code: $EXIT_CODE\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1

# Currently, Helm installation will never complete successfully because the DNS names in 
# the Connect:Direct config files (initparm.cfg, netmap.cfg and ndmapi.cfg) need to be 
# set to the running Connect:Direct container POD name

#if [ $EXIT_CODE -eq 0 ]
#then

#  printf "\n"
#  printf "Installation was successful.\n"
#  #printf "You may access B2Bi or SFG using the following URLs:\n"
#  #printf "\n"
#  #printf "B2Bi Dashboard: https://asi.$NameSpace.$IngressSubDomain/dashboard"
#  #printf "\n\n"
#  #printf "SFG Dashboard:  https://asi.$NameSpace.$IngressSubDomain/filegateway"
#  printf "\n"
#else

#  printf "\n"
#  printf "Installation was not successful!\n"
#  printf "Please examine your OpenShift cluster logs for details.\n"
#  printf "\n"

#  exit $EXIT_CODE
#fi

# Wait for Connect:Direct POD to become ready
# Get the basename of the POD that will be created for Connect:Direct from Chart.yaml which is
# located in the Connect:Direct helm chart directory

CDContainerName="$ReleaseName"'-'`grep -E ^name: < $INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/Chart.yaml | cut -d ' ' -f 2`'-0'

# Get status of Connect:Direct POD - Wait for "Running"
until oc get pod | grep "$CDContainerName" | grep "Running" 1>>/dev/null 2>&1
do
  ((attempt=$attempt+1))
  printf "Waiting for Connect:Direct POD to become ready ... $attempt\n"
  sleep 2
  printf "Sleeping 2 seconds ...\n"
done

# Wait for container to start, create config directories, etc.
sleep 15

# Fix initparm.cfg, netmap.cfg and ndmapi.cfg
CDToolkitPodName=`oc get pod | grep "$NameSpace"'-cditxpvc' | grep "Running"|cut -d ' ' -f 1`

oc exec -it $CDToolkitPodName -- /bin/bash -c "echo -n $CDContainerName>/tmp/CDContainerName.txt"

oc cp $INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/tools/fix-cd-config-files.sh $CDToolkitPodName:/tmp/fix-cd-config-files.sh

oc exec -it $CDToolkitPodName -- /bin/bash -c '/tmp/fix-cd-config-files.sh' 1>>/tmp/cd-itx-cluster-install.log 2>&1

oc delete pod $CDContainerName -n $NameSpace --grace-period=0 --force

exit $EXIT_CODE
