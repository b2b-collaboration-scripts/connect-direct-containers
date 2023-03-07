# CD-ITX Sidecar Container Build File
FROM registry.access.redhat.com/ubi8/ubi
#FROM alpine:latest

#RUN yum upgrade -y && yum install -y git curl which openssl zip unzip && yum clean all -y \
#  && curl -sL https://ibm.biz/idt-installer | bash \
#  && export DESIRED_VERSION=v2.12.3 \
#  && curl -sL https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash \
#  && curl -s https://mirror.openshift.com/pub/openshift-v4/clients/oc/4.3.5-202003041047.git.0.af13baf.el7/linux/oc.tar.gz | tar xz \
#  && mv oc /usr/local/bin/oc

ENV user=cduser
ENV group=cduser
ENV uid=1000
ENV gid=1000
ENV NFS_HOME=/connect

RUN dnf update -y

RUN groupadd -g ${gid} ${group}

RUN useradd -u ${uid} -g ${gid} -m -s /bin/bash ${user}

RUN mkdir -p ${NFS_HOME}'/CDFILES'

RUN chown -R ${uid}:${gid} $NFS_HOME

# expose mountd 20048/tcp and nfsd 2049/tcp and rpcbind 111/tcp
EXPOSE 2049/tcp 20048/tcp 111/tcp 111/udp

USER ${user}

ENTRYPOINT ["/bin/bash", "-ce", "tail -f /dev/null"]
