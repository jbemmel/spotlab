#!/bin/bash

# exit on non-zero return code
set -e

export HOME=/home/awslab

#
# Start script for Nuage Simplify container
#
function show_usage() {
 echo "Copyright (C) 2018-2021 Nokia, all rights reserved. Version 1.0 2021-05-16"
 echo "Usage: docker run -it --rm --device /dev/fuse --cap-add SYS_ADMIN -v /home/awslab:$HOME:Z eccloud/aws-lab [ git ]"
 echo "  (the ':Z' is for SELinux relabeling)"
 echo "  tip: You can add '--dns:x.x.x.x' to specify a DNS server for the Ansible host (this container) to use"
 echo ""
 echo "For your convenience, we can install a '$HOME/restart.sh' script with the correct startup parameters."
 echo "[provided sshd is running on the local host]"
 echo "If you do not want this, simply press CTRL+C"

 # /orig_adventure/install_adventure.sh 172.17.0.1
 exit $?
}

if [ $# == 0 ] || [ ! -d $HOME/ ]; then
 show_usage
fi

# Create log directory & designs directory; logs may be bind-mounted
LOG_PATH="/var/log/awslab"
if [ -d $LOG_PATH ]; then
chown -R awslab:awslab $LOG_PATH
else
LOG_PATH="$HOME/logs"
mkdir -p $LOG_PATH
fi

# Generate new host key if needed
mkdir -p --mode=700 $HOME/.ssh
if [ ! -e $HOME/.ssh/id_rsa ]; then
  ssh-keygen -h -f $HOME/.ssh/id_rsa -N '' || ( echo "Unable to create file, could be SELinux - try 'sudo chcon -Rt svirt_sandbox_file_t \`pwd\`'" && exit 1 )
fi

if [ ! -e $HOME/.ssh/config ]; then
cat > $HOME/.ssh/config << EOF
StrictHostKeyChecking   no
UserKnownHostsFile      /dev/null
EOF
  chmod 600 $HOME/.ssh/config
fi

# Asks for password if SSH key not registered with git
AWSLAB_ROOT=/awslab
if [ "$1" == "git" ]; then
 git config --global http.proxy ${http_proxy:-http://proxy.lbs.alcatel-lucent.com:8000}
 git config --global http.sslVerify "false"

 # mv /simplify /orig_simplify # Fails
 # rm -rf ${AWSLAB_ROOT}/*
 if [ ! -d /home/awslab/awslab_git ]; then
  git clone git@gitlab.com:jbemmel/aws-lab.git /home/awslab/awslab_git || true
 else
  cd /home/awslab/awslab_git && git pull
 fi
 ln -sf /home/awslab/awslab_git ${AWSLAB_ROOT}
 AWSLAB_RELEASE="[git]"
else
 ln -sf /awslab_src ${AWSLAB_ROOT}
fi

if [ ! -e $HOME/local_settings.yml ]; then
  cat > $HOME/local_settings.yml << EOF
#
# Local settings for AWS Lab
#

# (optional) server password; while it is bad security practice to keep these in text files,
# it can be convenient to configure this here rather than enter it on the command line each time
#
# become_pass: "xxxx"

#
# The server password is only used once, to setup SSH password access to each server.
# It won't be needed after the first run ( per target host )
#
# server_password: "XXXX"

#
# RedHat username/password for subscription manager, used to build Openstack VIM VM
#
# redhat_user: "XXXX"
# redhat_password: "XXXX"

# git username/password for checking out MetroAE
#
# git_user: "xxx"
# git_password: "xxx"

# AWS Credentials and S3 bucket
# AWS_ACCESS_KEY_ID: "xxxx"
# AWS_SECRET_ACCESS_KEY: "yyyy"
# AWS_REGION: "us-east-1"
# awslab_bucket: "awslab-files-unique"
awslab_cache_downloads_in_s3: true

# Optional HTTP proxy
# http_proxy: "http://xx"
# https_proxy: "http://xx"
# no_proxy: "list of IPs or fqdns"

# NTP servers to use if not specified in designs
# ntp_servers: []

# DNS servers to use if not specified, read from resolv.conf if not defined here
# dns_servers: []

EOF
else
sed -E 's/:[^:\/\/0-9]/=/g;s/$//g;s/\[//g;s/\]//g;s/ *= */=/g;s/^([^#])/export \1/g' $HOME/local_settings.yml > ${AWSLAB_ROOT}/local_settings.sh
fi

# Copy sample config to root dir, if not existing
# cp -n ${AWSLAB_ROOT}/sample-configs/minimal.json $HOME/nuage.json || true

# Generate default hosts inventory
if [ ! -e $HOME/hosts ]; then
cat > $HOME/hosts << EOF
# Sample hosts inventory with the Docker host IP
[servers]
s01 ansible_host="172.17.0.1"

[servers:vars]
# http_proxy=xxxx
# ansible_user=non-root
# server_password=xxxx
EOF
fi

# Clear Ansible tmp directory
# [ -d /files/.ansible/tmp ] && rm -rf /files/.ansible/tmp/*

echo "This is a Docker shell for AWS Lab $AWSLAB_RELEASE. Use <CTRL>-(p + q) to exit while keeping the container running - "
echo "alias 'launch_aws_instance' is defined for your convenience"
echo "Available host disk space under $HOME: `df -h $HOME | awk '/home\/awslab/ { print $4 }'`"
cat > /etc/profile.d/awslab.sh << EOF
# AWS Lab alias entries

# User specific aliases and functions
if [[ "$1" == "git" || "$1" == "root" ]]; then
alias ssh="setpriv --reuid 1100 \ssh"
alias scp="setpriv --reuid 1100 \scp"
fi

alias aled='echo "ls -r VSR*/*" | sftp -i /home/awslab/.ssh/id_rsa sftp@192.11.249.8'

# Run a given playbook as the 'awslab' user, and timestamp the log
run_playbook() {
  if [[ "$1" == "git" || "$1" == "root" ]]; then
   SETPRIV="setpriv --reuid 1100 --regid 1100 --clear-groups"
  fi
  time ANSIBLE_LOG_PATH=$LOG_PATH/ansible-\`date +%F_%R\`.log ANSIBLE_CONFIG=${AWSLAB_ROOT}/ansible.cfg \${SETPRIV} ansible-playbook ${AWSLAB_ROOT}/\$1.yml "\${@:2}"
}

_mount_s3() {
  AWSACCESSKEYID=\$AWS_ACCESS_KEY_ID AWSSECRETACCESSKEY=\$AWS_SECRET_ACCESS_KEY s3fs "awslab-\$AWS_REGION" "\$HOME/s3" -o use_rrs=1 -o use_cache="\$HOME/s3-cache"
}

alias launch_aws_instance="run_playbook launch_instance"
alias mount_s3="_mount_s3"

export LOG_PATH=$LOG_PATH
export NODE_PATH=/usr/local/ansible/node_modules/
export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_LOG_PATH="$LOG_PATH/ansible.log"
export PARAMIKO_HOST_KEY_AUTO_ADD=True
export TZ="America/Chicago"

# Source local settings
if [ -f ${AWSLAB_ROOT}/local_settings.sh ]; then
	. ${AWSLAB_ROOT}/local_settings.sh
fi

# Set prompt to include ADVenture release and host
PS1="[AWS Lab $AWSLAB_RELEASE on ${AWSLAB_HOST:-?} \W]\\$ "

EOF

# Create S3 mountpoint (TODO auto-load Docker images from there?)
mkdir -p "$HOME/s3" "$HOME/s3-cache"

# Change ownership to our awslab user
chown -R awslab:awslab $HOME

# Mount S3
# AWSACCESSKEYID=$AWS_ACCESS_KEY_ID AWSSECRETACCESSKEY=$AWS_SECRET_ACCESS_KEY s3fs "awslab-$AWS_REGION" "$HOME/s3" -o use_rrs=1 -o use_cache="$HOME/s3-cache"

#su - adventure -c "cd ${AWSLAB_ROOT} && \
#  NODE_PATH=/usr/local/ansible/node_modules/ ANSIBLE_SKIP_TAGS='${ANSIBLE_SKIP_TAGS}' \
#  LOG_PATH='${LOG_PATH}' AWSLAB_RELEASE='${AWSLAB_RELEASE}' node ./web-ui/backend/webserver.js" > $LOG_PATH/web.log 2>&1 &

# Update web UI and Digitizer to show ADVenture release in footer ( TODO separate single .js file )
# sed -i "s/\[\[SIMPLIFY_RELEASE\]\]/$SIMPLIFY_RELEASE/g" ${AWSLAB_ROOT}/web-ui/index.html
# sed -i "s/\[\[SIMPLIFY_RELEASE\]\]/$SIMPLIFY_RELEASE/g" ${AWSLAB_ROOT}/designer/js/Dialogs.js

if [[ "$1" == "git" || "$1" == "root" ]]; then
cd $HOME && /bin/bash --rcfile /etc/bashrc
else
su awslab --login
fi

exit $?
