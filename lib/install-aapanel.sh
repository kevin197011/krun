# Copyright (c) 2022 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# /bin/bash -c "$(curl -fsSL http://www.aapanel.com/script/install_6.0_en.sh)"
script_tmp='/tmp/install_6.0_en.sh'

curl -s http://www.aapanel.com/script/install_6.0_en.sh -o ${script_tmp}

echo "[Info] 涉及到交互选择,手动执行下面命令安装:"
echo "bash ${script_tmp} && rm -rf ${script_tmp}"
