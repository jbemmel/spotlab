FROM centos

ENTRYPOINT ["/orig_adventure/ecStart.sh"]
CMD [""]

# removed openpyxl for Excel, libssl2-dev
RUN yum install -y epel-release && yum update -y && \
    yum install -y python38 && \
    pip3 install --upgrade setuptools && \
    pip3 install ansible==2.9.0 netmiko netaddr==0.7.19 pexpect pyvmomi virtualenv lxml boto boto3 botocore awscli --upgrade && \
    yum clean all && rm -rf /var/cache/yum /tmp/* /var/tmp/*

#   mkdir -p /usr/local/ansible && cd /usr/local/ansible && \
#   npm i superagent superagent-proxy request agentkeepalive netmask express netmask body-parser multer http-proxy-middleware morgan && \


# Add support for s3fs to mount AWS S3 buckets
RUN yum install gcc libstdc++-devel gcc-c++ fuse fuse-devel curl-devel libxml2-devel mailcap git automake make openssl-devel -y && \
    cd /tmp && git clone https://github.com/s3fs-fuse/s3fs-fuse && cd s3fs-fuse && ./autogen.sh && \
    export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig && ./configure --prefix=/usr --with-openssl && make && make install && \
    rm -rf /tmp/s3fs-fuse

COPY ansible.cfg /etc/ansible/
COPY ssh_config /root/.ssh/config

# Define a non-root user to own processes, but don't create /home/awslab yet
RUN groupadd --gid 1100 awslab && \
    useradd -r -u 1100 -g awslab --no-create-home awslab && \
    chmod 600 /root/.ssh/config

COPY --chown=awslab:awslab . /orig_adventure

# Correct VirtualBox file attributes from shared folders
RUN find /orig_adventure -type f \( -not -iname "*.sh" \) -print0 | xargs -0 chmod 644 && \
    find /orig_adventure -type f \( -iname "*.sh" \) -print0 | xargs -0 chmod 755 && \
    find /orig_adventure -type d -print0 | xargs -0 chmod 755 && chmod 644 /etc/ansible/*

# Using a build arg to set the release tag, set a default for running docker build manually
ARG AWSLAB_RELEASE="[custom build]"
ENV AWSLAB_RELEASE=$AWSLAB_RELEASE

# USER adventure # Permission issues, need to start as root
