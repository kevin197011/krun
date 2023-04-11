# Copyright (c) 2022 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT


yum update -y && \
yum remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine && \
yum install -y yum-utils epel-release && \
yum-config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo && \
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && \ 
systemctl start docker && \
systemctl enable docker && \
docker version && \
docker compose version && \
# reboot
