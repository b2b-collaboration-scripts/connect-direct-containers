#!/bin/bash

# Install Docker

sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

sudo yum install -y yum-utils

sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

sudo yum install docker-ce docker-ce-cli containerd.io

sudo systemctl start docker

# Install oc
randomnum=$RANDOM

mkdir ocinstall-$randomnum ; cd ocinstall-$randomnum

sudo curl -o oc.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.8.8/openshift-client-linux.tar.gz

tar xvzf oc.tar.gz

sudo mv oc kubectl /usr/local/bin

cd .. ; /bin/rm -rf ocinstall-$randomnum

# Install helm
sudo curl -L https://mirror.openshift.com/pub/openshift-v4/clients/helm/latest/helm-linux-amd64 -o /usr/local/bin/helm

cd /usr/local/bin

sudo chmod 755 helm

# Install IBM Cloud CLI

sudo curl -sL https://ibm.biz/idt-installer | bash

# End
