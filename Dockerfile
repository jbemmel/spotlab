FROM centos

ENTRYPOINT ["/spotlab_src/ecStart.sh"]
CMD [""]

# removed openpyxl for Excel, libssl2-dev
RUN yum install -y epel-release && yum update -y && \
    yum install -y python38 sudo && \
    pip3 install --upgrade setuptools && \
    pip3 install ansible==2.10.7 netmiko netaddr==0.7.19 pexpect pyvmomi virtualenv lxml boto boto3 botocore awscli --upgrade && \
    yum clean all && rm -rf /var/cache/yum /tmp/* /var/tmp/*

#   mkdir -p /usr/local/ansible && cd /usr/local/ansible && \
#   npm i superagent superagent-proxy request agentkeepalive netmask express netmask body-parser multer http-proxy-middleware morgan && \

# Add docker client binary
ARG DOCKER_CLIENT=docker-20.10.6.tgz

RUN cd /tmp/ \
 && curl -sSL -O https://download.docker.com/linux/static/stable/x86_64/${DOCKER_CLIENT} \
 && tar zxf ${DOCKER_CLIENT} \
 && mkdir -p /usr/local/bin \
 && mv ./docker/docker /usr/local/bin \
 && chmod +x /usr/local/bin/docker \
 && rm -rf /tmp/*

# Add support for s3fs to mount AWS S3 buckets
RUN yum install gcc libstdc++-devel gcc-c++ fuse fuse-devel curl-devel libxml2-devel mailcap git automake make openssl-devel -y && \
    cd /tmp && git clone https://github.com/s3fs-fuse/s3fs-fuse && cd s3fs-fuse && ./autogen.sh && \
    export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig && ./configure --prefix=/usr --with-openssl && make && make install && \
    rm -rf /tmp/s3fs-fuse

COPY ansible.cfg /etc/ansible/
COPY ssh_config /root/.ssh/config

# Define a non-root user to own processes, but don't create /home/spotlab yet
RUN groupadd --gid 1100 spotlab && \
    useradd -r -u 1100 -g spotlab --no-create-home spotlab && \
    chmod 600 /root/.ssh/config && \
    echo "spotlab	ALL=(ALL)	NOPASSWD: ALL" >> /etc/sudoers

COPY --chown=spotlab:spotlab . /spotlab_src

# Correct VirtualBox file attributes from shared folders; fix Docker
RUN find /spotlab_src -type f \( -not -iname "*.sh" \) -print0 | xargs -0 chmod 644 && \
    find /spotlab_src -type f \( -iname "*.sh" \) -print0 | xargs -0 chmod 755 && \
    find /spotlab_src -type d -print0 | xargs -0 chmod 755 && chmod 644 /etc/ansible/*

# sed -i 's|#mount_program|mount_program|g' /etc/containers/storage.conf

# Using a build arg to set the release tag, set a default for running docker build manually
ARG SPOTLAB_RELEASE="[custom build]"
ENV SPOTLAB_RELEASE=$SPOTLAB_RELEASE

# USER adventure # Permission issues, need to start as root
