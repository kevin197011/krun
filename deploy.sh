# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

install_path=${deploy_path:-'$HOME/.krun'}

mkdir -pv ${install_path}/bin
mkdir -pv ${install_path}/config
curl -o ${install_path}/bin/krun https://raw.githubusercontent.com/kevin197011/krun/main/bin/krun
chmod +x ${install_path}/bin/krun

# mac
command -v brew >/dev/null && {
  grep -q "${install_path}/bin" ~/.zshrc || echo "export PATH=\$PATH:${install_path}/bin" >>~/.zshrc
  zsh && krun status
  exit 0
}

# other
grep -q "${install_path}/bin" ~/.bashrc || echo "export PATH=\$PATH:${install_path}/bin" >>~/.bashrc
bash && krun status
exit 0
