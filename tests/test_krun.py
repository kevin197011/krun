#!/usr/bin/env python3
# Copyright (c) 2023 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

try:
    # after python 3.x
    from urllib.request import Request, urlopen
except ImportError:
    # for python 2.x
    from urllib2 import Request, urlopen

import re

# default url
_default_repo_name = 'kevin197011'
_github_repo = 'https://github.com/{}/krun/tree/main/lib'.format(
    _default_repo_name)
_github_repo_sh = 'https://raw.githubusercontent.com/{}/krun/main/lib'.format(
    _default_repo_name)

# ua
ua = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36'


# main
_index = 1
_req = Request(_github_repo)
_req.add_header('User-Agent', ua)
_content = urlopen(_req).read().decode('utf-8')
# print(_content)
# _pattern = re.compile(r'"lib/(\S+\.(?:sh|py|rb|pl))",')
_pattern = re.compile(r'lib/(.*?)",')
_vals = _pattern.findall(_content)
print(_vals)
# for item in _vals:
#     print("  - [{0}]{1}".format(_index, item))
#     _index += 1
