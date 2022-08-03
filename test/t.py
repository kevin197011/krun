# Copyright (c) 2022 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT


import re


pattern = re.compile(r'>(\S+\.sh|py|rb|pl)</a>')

with open('test/data.txt', 'r') as f:
    # print(f.read())
    vals = pattern.findall(f.read())

    print('  - ' + '\n  - '.join(vals))