# Copyright (c) 2022 kk
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT


# https://maven.apache.org/docs/history.html
_version='3.8.6'
# https://maven.apache.org/download.cgi
_url="https://dlcdn.apache.org/maven/maven-3/${_version}/binaries/apache-maven-${_version}-bin.tar.gz"
# deploy path
_deploy_path='/usr/local/maven'

cd /tmp
mkdir -p ${_deploy_path}
wget --no-check-certificate ${_url}
tar -xzf ${_url##*/} --strip-components 1 -C ${_deploy_path}

tee /etc/profile.d/maven.sh &>/dev/null <<EOF
export M2_HOME=$_deploy_path
export M2=\$M2_HOME/bin
export PATH=\$M2:\$PATH
EOF

source /etc/profile
mvn -version
rm -rf ${_url##*/}