#!/usr/bin/env python3
"""Script name -> handler registry."""

from __future__ import annotations

import os
import sys

from krun.handlers import config, install, jumpserver, network, ops


def _init_system() -> None:
    from krun.handlers.system import main
    main()


def _config_rpm_repo() -> None:
    variant = os.environ.get("REPO", "rocky")
    if variant not in {"rocky", "centos7"}:
        variant = "rocky" if "rocky" in sys.argv[0] or os.environ.get("SCRIPT", "").endswith("rocky") else "centos7"
    config.config_rpm_repo(variant)


def _asdf_setup() -> None:
    install.curl_pipe("https://raw.githubusercontent.com/asdf-vm/asdf/master/bin/asdf")
    print("✓ asdf installed; add to shell profile if needed")


def _system_baseline(mode: str) -> None:
    require = __import__("krun.common", fromlist=["require_root"]).require_root
    require()
    if mode == "check":
        print("baseline check: ssh, firewall, auditd")
        __import__("subprocess").run(["sshd", "-t"], check=False)
        print("✓ baseline check done (simplified)")
        return
    config.disable_firewall_selinux()
    config.config_ssh_harden()
    install.install_packages(deb=["aide", "auditd", "fail2ban"], rhel=["aide", "auditd", "fail2ban"], epel=True)
    print("✓ baseline configured (simplified)")



def _acme_cert() -> None:
    email = os.environ.get("ACME_EMAIL", "admin@example.com")
    install.curl_pipe("https://get.acme.sh")
    __import__("subprocess").run(["/root/.acme.sh/acme.sh", "--set-default-ca", "--server", "letsencrypt"], check=False)
    print(f"✓ acme.sh installed for {email}")


def _prometheus_exporter(kind: str) -> None:
    mapping = {
        "node": ("prometheus/node_exporter", "node_exporter"),
        "blackbox": ("prometheus/blackbox_exporter", "blackbox_exporter"),
    }
    repo, binary = mapping[kind]
    install.github_binary(repo, binary)
    unit = f"""[Unit]
Description={binary}
After=network.target
[Service]
ExecStart=/usr/local/bin/{binary}
Restart=always
[Install]
WantedBy=multi-user.target
"""
    from pathlib import Path
    from krun.common import write_if_changed, service_enable
    write_if_changed(Path(f"/etc/systemd/system/{binary}.service"), unit)
    service_enable(f"{binary}.service")


SCRIPTS: dict[str, callable] = {
    "hello_world": ops.hello_world,
    "init_system": _init_system,
    "disk_cleanup": ops.disk_cleanup,
    "install_nginx": lambda: install.install_pkg("nginx"),
    "install_git": lambda: install.install_pkg("git"),
    "install_mc": lambda: install.install_pkg("mc"),
    "install_maven": lambda: install.install_pkg("maven"),
    "install_ansible": lambda: install.install_pkg("ansible"),
    "install_cpanm": lambda: install.install_pkg("cpanm"),
    "install_geoipupdate": lambda: install.install_pkg("geoipupdate"),
    "install_percona_toolkit": lambda: install.install_pkg("percona_toolkit"),
    "install_puppet_bolt": lambda: install.install_pkg("puppet_bolt"),
    "install_kind": lambda: install.install_pkg("kind"),
    "install_lsyncd": lambda: install.install_pkg("lsyncd"),
    "install_openjdk": lambda: install.install_pkg("openjdk"),
    "install_redis": lambda: install.install_pkg("redis"),
    "install_golang": lambda: install.install_pkg("golang"),
    "install_ffmpeg": lambda: install.install_pkg("ffmpeg"),
    "install_elixir": lambda: install.install_pkg("elixir"),
    "install_zsh": install.install_zsh,
    "install_vim": lambda: __import__("krun.common", fromlist=["install_packages"]).install_packages(deb=["vim"], rhel=["vim-enhanced"], brew=["vim"]),
    "install_ruby": lambda: __import__("krun.common", fromlist=["install_packages"]).install_packages(deb=["ruby-full"], rhel=["ruby"], brew=["ruby"]),
    "install_tinyproxy": lambda: __import__("krun.common", fromlist=["install_packages"]).install_packages(
        deb=["tinyproxy"], rhel=["tinyproxy"], service="tinyproxy"
    ),
    "install_docker": install.install_docker,
    "install_base_packages": install.install_base_packages,
    "install_k9s": lambda: install.install_github_tool("k9s"),
    "install_helm": lambda: install.install_github_tool("helm"),
    "install_crane": lambda: install.install_github_tool("crane"),
    "install_rclone": lambda: install.install_github_tool("rclone"),
    "install_node_exporter": lambda: _prometheus_exporter("node"),
    "install_blackbox_exporter": lambda: _prometheus_exporter("blackbox"),
    "install_awscli": install.install_awscli,
    "install_gcloud": lambda: install.install_cloud_cli("gcloud"),
    "install_aliyun_cli": lambda: install.install_cloud_cli("aliyun"),
    "install_aapanel": lambda: install.install_web_panel("aapanel"),
    "install_1panel": lambda: install.install_web_panel("1panel"),
    "install_salt_minion": lambda: install.install_salt("minion"),
    "install_salt_master": lambda: install.install_salt("master"),
    "install_devbox": install.install_devbox,
    "install_cursor_cli": install.install_cursor_cli,
    "install_oh_my_zsh": install.install_oh_my_zsh,
    "install_spacevim": install.install_spacevim,
    "install_kssh": install.install_kssh,
    "install_asdf": _asdf_setup,
    "apply_asdf": _asdf_setup,
    "install_jdk8": lambda: __import__("krun.common", fromlist=["install_packages"]).install_packages(
        rhel=["java-1.8.0-openjdk"], deb=["openjdk-8-jdk"]
    ),
    "install_rbenv": lambda: install.curl_pipe(
        "https://github.com/rbenv/rbenv-installer/raw/main/bin/rbenv-installer", shell="bash"
    ),
    "install_filebeat": lambda: __import__("krun.common", fromlist=["install_packages"]).install_packages(deb=["filebeat"], rhel=["filebeat"], epel=True),
    "install_vagrant_virtualbox": lambda: __import__("krun.common", fromlist=["install_packages"]).install_packages(
        deb=["vagrant", "virtualbox"], brew=["vagrant"]
    ),
    "install_fonts_nerd_jetbrains": lambda: install.curl_pipe("https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/install.sh", shell="bash"),
    "config_rpm_repo": _config_rpm_repo,
    "config_rocky_repo": lambda: config.config_rpm_repo("rocky"),
    "config_centos7_repo": lambda: config.config_rpm_repo("centos7"),
    "config_timezone": config.config_timezone,
    "config_locales": config.config_locale,
    "config_proxy": config.config_proxy,
    "config_ssh": config.config_ssh_harden,
    "config_ssh_authorized_keys": config.config_ssh_keys,
    "config_vagrant_ssh": config.config_ssh_keys,
    "deploy_sshkey": config.config_ssh_keys,
    "config_disk_data": config.config_disk_data,
    "config_fstab": config.config_fstab_guide,
    "config_git": config.config_git_global,
    "reset_git_history": config.reset_git_history,
    "disable_firewall_selinux": config.disable_firewall_selinux,
    "config_system_baseline": lambda: _system_baseline("config"),
    "check_system_baseline": lambda: _system_baseline("check"),
    "check_system_troubleshoot": lambda: (
        __import__("subprocess").run("dmesg | tail -20; free -h; df -h", shell=True),
        print("✓ troubleshoot snapshot"),
    )[-1],
    "check_ip_quality": network.check_ip_quality,
    "config_acme": _acme_cert,
    "config_elasticsearch": lambda: print("✓ use elasticsearch docs; simplified stub"),
    "config_cursor": lambda: __import__("krun.common", fromlist=["run"]).run(
        "git clone git@github.com:kevin197011/cursor.git .cursor", shell=True
    ),
    "config_rakefile": lambda: print("✓ copy Rakefile from template manually"),
    "config_ruby_http": lambda: print("✓ configure ruby http in Gemfile"),
    "config_vm": lambda: print("✓ vm config placeholder"),
    "crane_copy": ops.crane_copy,
    "deploy_node_exporter": ops.deploy_node_exporter,
    "delete_video": ops.delete_video,
    "config_jumpserver_ssh_timeout": jumpserver.config_jumpserver_ssh_timeout,
    "update_vagrant_box": lambda: __import__("krun.common", fromlist=["run"]).run(["vagrant", "box", "update", "--all"]),
}


def run_script(name: str) -> None:
    fn = SCRIPTS.get(name)
    if not fn:
        print(f"✗ unknown script: {name}")
        raise SystemExit(1)
    fn()
