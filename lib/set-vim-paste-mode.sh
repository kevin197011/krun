# Copyright (c) 2022 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

export vim_config_path='/etc/vimrc' && (grep -q 'set paste' ${vim_config_path} || echo 'set paste' >> ${vim_config_path})