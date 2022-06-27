# Copyright (c) 2022 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

if [[ command -v yum >/dev/null 2>&1 ]]; then
    yum install -y git gcc gcc-c++
    yum install -y openssl-devel zlib-devel
else
    apt install -y git-all build-essential manpages-dev
    apt install -y libssl-dev zlib1g zlib1g-dev
fi

cd /root
rm -rf /root/.asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch master
grep -q '. $HOME/.asdf/asdf.sh' ~/.bashrc || echo '. $HOME/.asdf/asdf.sh' >>~/.bashrc
grep -q '. $HOME/.asdf/completions/asdf.bash' ~/.bashrc || echo '. $HOME/.asdf/completions/asdf.bash' >>~/.bashrc
. ~/.bashrc
asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git
asdf install ruby 3.1.2
asdf global ruby 3.1.2
ruby -v
