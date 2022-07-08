# Copyright (c) 2022 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# delete $(pwd)/ log

current_path=${1:-'/www/wwwroot'}

find ${current_path} -iname '*.log' -delete
