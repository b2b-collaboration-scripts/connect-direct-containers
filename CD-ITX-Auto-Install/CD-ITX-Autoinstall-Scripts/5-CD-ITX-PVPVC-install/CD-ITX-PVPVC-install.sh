#!/bin/bash
# CD-ITX-PVPVC-install.sh

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

# Initialize saved values file for final helm install script
>$INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/5-CD-ITX-PVPVC-install/5-savedvalues

# Make sure we're using $NameSpace project namespace
printf "\n"
printf "Now using \"$NameSpace\" namespace ...\n\n"
printf "Now using \"$NameSpace\" namespace ...\n\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1
oc project $NameSpace 1>>/tmp/cd-itx-cluster-install.log 2>&1

# Create a service account for CD-ITX
printf "Creating CD-ITX Service Account ...\n\n"

export CDITXServiceAccount="$NameSpace"'-cd-itx'

oc create serviceaccount "$CDITXServiceAccount" 1>>/tmp/cd-itx-cluster-install.log 2>&1
printf "CDITXServiceAccount = $CDITXServiceAccount\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1
printf 'CDITXServiceAccount='"\"$CDITXServiceAccount\"\n">>$INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/5-CD-ITX-PVPVC-install/5-savedvalues

# Give CD-ITX user anyuid security context constraints
printf "Creating CD-ITX Privileged Security Context ...\n\n"
oc adm policy add-scc-to-user anyuid -z default -n "$NameSpace" 1>>/tmp/cd-itx-cluster-install.log 2>&1

printf "\n########## Now Deploying CD-ITX PV-PVC ##########\n\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1

# Generate a new cd-itx-pvpvc.yaml file from template with current server/path/region/zone
printf "Generate cditxpvc.yaml file from template ...\n\n"

# Initialize the yaml file
>$INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/cditxpvc.yaml

# Build cditxpvc.yaml file
printf "# CD-ITX PVC Deployment File - cditxpvc.yaml\n" >>$INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/cditxpvc.yaml
printf "# Date:       `date`\n" >>$INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/cditxpvc.yaml
printf "# NameSpace:  $NameSpace\n" >>$INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/cditxpvc.yaml

while IFS='' read -r line || [[ -n "${line}" ]];
do

  # Using '^' as a search delimiter in sed rather than '/' to avoid errors due to paths that contain the slash character
  echo "$line" | grep "NAMESPACE" && line=$(echo "$line" | sed "s^NAMESPACE^$NameSpace^g")

  echo "$line" >>$INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/cditxpvc.yaml

done <<EOF

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
 name: NAMESPACE-cditxpvc
spec:
 accessModes:
   - ReadWriteOnce
 persistentVolumeReclaimPolicy: "Delete"
 resources:
   requests:
     storage: 20Gi
 storageClassName: "ibmc-file-gold"
EOF

# Deploy PVC
printf "Deploying PVC\'s ...\n\n"
oc create -f $INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/cditxpvc.yaml -n $NameSpace 1>>/tmp/cd-itx-cluster-install.log 2>&1

# Wait for persistent volume to be automatically created
until oc get pvc -n "$NameSpace" | grep 'cditxpvc' | grep 'Bound' 1>>/dev/null 1>>/tmp/cd-itx-cluster-install.log 2>&1
do
  ((attempt=$attempt+1))
  printf "Waiting for PVC to become ready ... $attempt\n"
  sleep 2
  printf "Sleeping 2 seconds ...\n"
done

# Build cditx-toolkitdeploy.yaml file
printf "# B2Bi-SFG PV/PVC Deployment File - cditx-toolkitdeploy.yaml\n" >>$INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/cditx-toolkitdeploy.yaml
printf "# Date:       `date`\n" >>$INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/cditx-toolkitdeploy.yaml
printf "# NameSpace:  $NameSpace\n" >>$INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/cditx-toolkitdeploy.yaml

while IFS='' read -r line || [[ -n "${line}" ]];
do

  # Using '^' as a search delimiter in sed rather than '/' to avoid errors due to paths that contain the slash character
  echo "$line" | grep "NAMESPACE" && line=$(echo "$line" | sed "s^NAMESPACE^$NameSpace^g")

  echo "$line" >>$INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/cditx-toolkitdeploy.yaml

done <<EOF

apiVersion: apps/v1
kind: Deployment
metadata:
  name: NAMESPACE-cditxpvc
spec:
  replicas: 1
  selector:
    matchLabels:
      app: NAMESPACE-cditxpvc
  template:
    metadata:
      labels:
        app: NAMESPACE-cditxpvc
    spec:
#      serviceAccount: NAMESPACE-cditxpvc
      containers:
      - name: NAMESPACE-cditxpvc
        image: ghcr.io/icechasm/cditxsc:latest
        command: ["/bin/bash", "-ce", "tail -f /dev/null"]
        volumeMounts:
        - mountPath: /connect
          name: volume
      volumes:
      - name: volume
        persistentVolumeClaim:
          claimName: NAMESPACE-cditxpvc
      initContainers:
      - name: permissionsfix
        image: alpine:latest
        command: ["/bin/sh", "-c"]
        args:
          - chown 1000:1000 /mount;
        volumeMounts:
        - name: volume
          mountPath: /mount
EOF

# Deploy Toolkit Container
printf "Deploying Toolkit Container ...\n\n"
oc create -f $INSTALL_BASE_DIR/CD-ITX-Containers/${CDHelmChartName%\-*}/cditx-toolkitdeploy.yaml -n $NameSpace 1>>/tmp/cd-itx-cluster-install.log 2>&1

attempt=0

# Get status of toolkit pod - Wait for "Running"
until oc get pod | grep "$NameSpace"'-cditxpvc' | grep "Running" 1>>/dev/null 2>&1
do
  ((attempt=$attempt+1))
  printf "Waiting for pod to become ready ... $attempt\n"
  sleep 2
  printf "Sleeping 2 seconds ...\n"
done

# Copy Secure Plus certificate to Toolkit POD
CDToolkitPodName=`oc get pod | grep "$NameSpace"'-cditxpvc' | grep "Running"|cut -d ' ' -f 1`

# Create 'CDFILES' directory and copy cert to POD/directory
oc exec -it $CDToolkitPodName -- /bin/bash -c 'mkdir -p /connect/CDFILES' 1>>/tmp/cd-itx-cluster-install.log 2>&1

oc cp $INSTALL_BASE_DIR/privkey.pem $CDToolkitPodName:/connect/CDFILES/privkey.pem 1>>/tmp/cd-itx-cluster-install.log 2>&1

# Get PVC info for B2Bi-SFG Deploy
printf "Getting PV-PVC info ...\n\n"

printf "\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1

oc get pvc -n "$NameSpace" 1>>/tmp/cd-itx-cluster-install.log 2>&1

toolkitPV=`oc get pvc -n "$NameSpace" | grep 'cditxpvc' | perl -lane 'print $F[2]'`
printf "toolkitPV = $toolkitPV\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1
printf 'toolkitPV='"\"$toolkitPV\"\n">>$INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/5-CD-ITX-PVPVC-install/5-savedvalues

Ref4_Server=`oc describe pv "$toolkitPV" | grep -m1 "Server:" | perl -lane 'print $F[1]'`
printf "Ref4_Server = $Ref4_Server\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1
printf 'Ref4_Server='"\"$Ref4_Server\"\n">>$INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/5-CD-ITX-PVPVC-install/5-savedvalues

Ref4_Path=`oc describe pv "$toolkitPV" | grep -m1 "Path:" | perl -lane 'print $F[1]'`
printf "Ref4_Path = $Ref4_Path\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1
printf 'Ref4_Path='"\"$Ref4_Path\"\n">>$INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/5-CD-ITX-PVPVC-install/5-savedvalues

Ref4_Region=`oc describe pv "$toolkitPV" | grep -m1 "region=" | perl -F= -lane 'print $F[1]'`
printf "Ref4_Region = $Ref4_Region\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1
printf 'Ref4_Region='"\"$Ref4_Region\"\n">>$INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/5-CD-ITX-PVPVC-install/5-savedvalues

Ref4_Zone=`oc describe pv "$toolkitPV" | grep -m1 "zone=" | perl -F= -lane 'print $F[1]'`
printf "Ref4_Zone = $Ref4_Zone\n" 1>>/tmp/cd-itx-cluster-install.log 2>&1
printf 'Ref4_Zone='"\"$Ref4_Zone\"\n">>$INSTALL_BASE_DIR/CD-ITX-Autoinstall-Scripts/5-CD-ITX-PVPVC-install/5-savedvalues

exit 0