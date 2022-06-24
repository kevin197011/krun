# Copyright (c) 2022 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

yum remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine && \
yum install -y yum-utils && \
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo && \
yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin && \
yum install docker-compose -y && \
systemctl start docker && \
systemctl enable docker