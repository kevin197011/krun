# Copyright (c) 2022 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

yum install git gcc gcc-c++ -y \
&& yum install -y openssl-devel zlib-devel \
&& cd /root \
&& rm -rf /root/.asdf \
&& git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.9.0  \
&& grep -q '. $HOME/.asdf/asdf.sh' ~/.bashrc || echo '. $HOME/.asdf/asdf.sh' >>~/.bashrc \
&& grep -q '. $HOME/.asdf/completions/asdf.bash' ~/.bashrc || echo '. $HOME/.asdf/completions/asdf.bash' >>~/.bashrc \
&& . ~/.bashrc \
&& asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git \
&& asdf install ruby 3.1.2 \
&& asdf global ruby 3.1.2 \
&& ruby -v
