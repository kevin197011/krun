# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import os

file_path = __file__

# print(os.path.pardir(file_path))
print(os.path.abspath(os.path.join(os.path.dirname(__file__), os.path.pardir)))
