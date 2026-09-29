"""Package and special installers."""

from __future__ import annotations

import os
from pathlib import Path

from krun.common import (
    curl_pipe,
    curl_shell,
    github_binary,
    install_packages,
    platform,
    read_os_release,
    require_root,
    run,
    run_ok,
    service_enable,
    has_cmd,
    pm_rhel,
    write_if_changed,
)

# deb, rhel, brew, service, epel
PKG = {
    "nginx": (["nginx"], ["nginx"], ["nginx"], "nginx", False),
    "git": (["git"], ["git"], ["git"], None, False),
    "mc": (["mc"], ["mc"], None, None, True),
    "maven": (["maven"], ["maven"], ["maven"], None, False),
    "ansible": (["ansible"], ["ansible"], ["ansible"], None, False),
    "cpanm": (["cpanm"], ["perl-App-cpanminus"], ["cpanm"], None, False),
    "geoipupdate": (["geoipupdate"], ["geoipupdate"], None, None, True),
    "percona_toolkit": (["percona-toolkit"], ["percona-toolkit"], None, None, True),
    "puppet_bolt": (["puppet-bolt"], None, None, None, False),
    "kind": (None, None, ["kind"], None, False),
    "lsyncd": (["lsyncd"], ["lsyncd"], None, "lsyncd", True),
    "openjdk": (["openjdk-17-jdk"], ["java-17-openjdk"], ["openjdk"], None, False),
    "redis": (["redis-server"], ["redis"], ["redis"], "redis", False),
    "golang": (["golang-go"], ["golang"], ["go"], None, False),
    "ffmpeg": (["ffmpeg"], ["ffmpeg"], ["ffmpeg"], None, True),
    "elixir": (["elixir"], ["elixir"], ["elixir"], None, True),
}


def install_zsh() -> None:
    install_packages(deb=["zsh"], rhel=["zsh"], brew=["zsh"])
    print("✓ zsh done")


def install_pkg(name: str) -> None:
    spec = PKG.get(name)
    if not spec:
        print(f"✗ unknown package task: {name}")
        raise SystemExit(1)
    deb, rhel, brew, service, epel = spec
    print(f"installing {name}")
    install_packages(deb=deb, rhel=rhel, brew=brew, service=service, epel=epel)
    print(f"✓ {name} done")


def install_docker() -> None:
    require_root()
    plat = platform()
    if plat == "deb":
        run("apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true", shell=True)
        env = {**os.environ, "DEBIAN_FRONTEND": "noninteractive"}
        run(["apt-get", "update"], env=env)
        run(["apt-get", "install", "-y", "ca-certificates", "curl", "gnupg"], env=env)
        os_release = read_os_release()
        dist = os_release.get("ID", "ubuntu")
        codename = os_release.get("VERSION_CODENAME", "bookworm")
        gpg_url = f"https://download.docker.com/linux/{dist}/gpg"
        run(
            f"install -d /etc/apt/keyrings && {curl_shell(gpg_url)} "
            f"| gpg --dearmor -o /etc/apt/keyrings/docker.gpg && "
            f'echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] '
            f'https://download.docker.com/linux/{dist} {codename} stable" > /etc/apt/sources.list.d/docker.list',
            shell=True,
        )
        run(["apt-get", "update"], env=env)
        run(["apt-get", "install", "-y", "docker-ce", "docker-ce-cli", "containerd.io",
             "docker-buildx-plugin", "docker-compose-plugin"], env=env)
    elif plat == "rhel":
        pm = pm_rhel()
        run(f"{pm} remove -y docker docker-client docker-common podman runc 2>/dev/null || true", shell=True)
        run([pm, "install", "-y", "yum-utils"])
        run([pm, "config-manager", "--add-repo", "https://download.docker.com/linux/centos/docker-ce.repo"])
        run([pm, "install", "-y", "docker-ce", "docker-ce-cli", "containerd.io",
             "docker-buildx-plugin", "docker-compose-plugin"])
    else:
        print("✗ docker install supports deb/rhel only")
        raise SystemExit(1)
    service_enable("docker")
    print("✓ docker installed")


def install_base_packages() -> None:
    require_root()
    deb = ["vim", "git", "tree", "lrzsz", "lsof", "net-tools", "wget", "curl", "jq", "rsync", "chrony", "unzip", "telnet"]
    rhel = deb + ["bind-utils", "yum-utils"]
    install_packages(deb=deb, rhel=rhel, epel=True)
    print("✓ base packages done")


def install_web_panel(panel: str) -> None:
    urls = {
        "aapanel": "https://www.aapanel.com/script/install_6.0_en.sh",
        "1panel": "https://resource.fit2cloud.com/1panel/package/quick_start.sh",
    }
    url = urls.get(panel)
    if not url:
        raise SystemExit(1)
    curl_pipe(url)


def install_salt(role: str) -> None:
    require_root()
    flag = "-M" if role == "master" else ""
    salt_url = "https://github.com/saltstack/salt-bootstrap/releases/latest/download/bootstrap-salt.sh"
    run(f"{curl_shell(salt_url)} | sh -s -- stable {flag}".strip(), shell=True)
    print(f"✓ salt {role} done")


def install_github_tool(tool: str) -> None:
    mapping = {
        "k9s": ("derailed/k9s", "k9s"),
        "helm": ("helm/helm", "helm"),
        "crane": ("google/go-containerregistry", "crane"),
        "rclone": ("rclone/rclone", "rclone"),
    }
    repo, binary = mapping[tool]
    github_binary(repo, binary)


def install_awscli() -> None:
    require_root()
    if platform() == "deb":
        aws_url = "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip"
        run(f"{curl_shell(aws_url, output='/tmp/aws.zip')} && unzip -qo /tmp/aws.zip -d /tmp && /tmp/aws/install", shell=True)
    else:
        install_packages(rhel=["awscli"], deb=["awscli"])
    print("✓ awscli done")


def install_cloud_cli(vendor: str) -> None:
    require_root()
    if vendor == "gcloud":
        curl_pipe("https://sdk.cloud.google.com", shell="bash")
    elif vendor == "aliyun":
        aliyun_url = "https://aliyuncli.alicdn.com/aliyun-cli-linux-latest-amd64.tgz"
        run(f"{curl_shell(aliyun_url)} | tar xz -C /usr/local/bin", shell=True)
    print(f"✓ {vendor} cli done")


def install_devbox() -> None:
    curl_pipe("https://get.jetpack.io/devbox", shell="bash")


def install_cursor_cli() -> None:
    curl_pipe("https://cursor.com/install", shell="bash")


def install_oh_my_zsh() -> None:
    zsh_url = "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    run(f'sh -c "$({curl_shell(zsh_url)})" "" --unattended', shell=True)


def install_spacevim() -> None:
    curl_pipe("https://spacevim.org/install.sh")


def install_kssh() -> None:
    if platform() != "mac":
        print("✗ kssh is macOS only")
        raise SystemExit(1)
    run("git clone https://github.com/kevin197011/kssh.git ~/.kssh && cd ~/.kssh && bundle install", shell=True)


def install_mysql() -> None:
    """Install MySQL 8.4 LTS from the official community repo."""
    plat = platform()
    if plat == "mac":
        run(["brew", "install", "mysql@8.4"])
        run(["brew", "services", "start", "mysql@8.4"], check=False)
        print("✓ MySQL 8.4 installed via Homebrew")
        return

    require_root()
    if run_ok("mysqld --version 2>/dev/null | grep -q 'Ver 8.'"):
        print("✓ MySQL 8 already installed")
        _mysql_enable()
        return

    if plat == "rhel":
        osr = read_os_release()
        major = osr.get("VERSION_ID", "9").split(".", 1)[0]
        rpms = {
            "7": "https://repo.mysql.com/mysql84-community-release-el7-1.noarch.rpm",
            "8": "https://repo.mysql.com/mysql84-community-release-el8-1.noarch.rpm",
            "9": "https://repo.mysql.com/mysql84-community-release-el9-1.noarch.rpm",
        }
        url = rpms.get(major)
        if not url:
            print(f"✗ unsupported RHEL major: {major}")
            raise SystemExit(1)
        pm = pm_rhel()
        run("rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 || true", shell=True)
        run("rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2025 || true", shell=True)
        run(f"{pm} module disable -y mysql >/dev/null 2>&1 || true", shell=True)
        run([pm, "install", "-y", url])
        run([pm, "install", "-y", "mysql-community-server", "mysql-community-client"])
    elif plat == "deb":
        osr = read_os_release()
        family = "ubuntu" if osr.get("ID") == "ubuntu" or "ubuntu" in osr.get("ID_LIKE", "") else "debian"
        codename = osr.get("VERSION_CODENAME", "")
        if not codename:
            print("✗ cannot read VERSION_CODENAME")
            raise SystemExit(1)
        env = {**os.environ, "DEBIAN_FRONTEND": "noninteractive"}
        run(["apt-get", "update"], env=env)
        run(["apt-get", "install", "-y", "ca-certificates", "curl", "gnupg"], env=env)
        run(
            "install -d /usr/share/keyrings && "
            "curl -fsSL https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 | gpg --dearmor -o /usr/share/keyrings/mysql-2023.gpg && "
            "curl -fsSL https://repo.mysql.com/RPM-GPG-KEY-mysql-2025 | gpg --dearmor -o /usr/share/keyrings/mysql-2025.gpg && "
            "cat /usr/share/keyrings/mysql-2023.gpg /usr/share/keyrings/mysql-2025.gpg > /usr/share/keyrings/mysql.gpg && "
            f'echo "deb [signed-by=/usr/share/keyrings/mysql.gpg] https://repo.mysql.com/apt/{family} {codename} mysql-8.4-lts" '
            "> /etc/apt/sources.list.d/mysql.list",
            shell=True,
        )
        run(["apt-get", "update"], env=env)
        run(["apt-get", "install", "-y", "mysql-community-server", "mysql-community-client"], env=env)
    else:
        print("✗ mysql install supports deb/rhel/mac only")
        raise SystemExit(1)
    _mysql_enable()
    print("✓ MySQL 8.4 LTS installed")


def _mysql_enable() -> None:
    import subprocess

    listed = subprocess.run(
        ["systemctl", "list-unit-files", "mysql.service", "mysqld.service"],
        capture_output=True, text=True, check=False,
    ).stdout
    svc = "mysql" if "mysql.service" in listed and "mysqld.service" not in listed else "mysqld"
    if "mysqld.service" in listed:
        svc = "mysqld"
    elif "mysql.service" in listed:
        svc = "mysql"
    service_enable(svc)
    print(f"✓ MySQL service {svc} enabled")
    log = subprocess.run(
        "grep -h 'temporary password' /var/log/mysqld.log /var/log/mysql/error.log 2>/dev/null | tail -1",
        shell=True, capture_output=True, text=True, check=False,
    )
    line = log.stdout.strip()
    if line:
        print(line)
    password = os.environ.get("MYSQL_ROOT_PASSWORD", "")
    if not password:
        print("  mysql -uroot -p")
        return
    if not line:
        print("⚠ MYSQL_ROOT_PASSWORD set but no temporary password in the log")
        return
    tmp = line.split()[-1]
    ok = run([
        "mysql", "--connect-expired-password", "-uroot", f"-p{tmp}", "-e",
        f"ALTER USER 'root'@'localhost' IDENTIFIED BY '{password}';",
    ])
    print("✓ root password updated" if ok == 0 else "⚠ failed to set MYSQL_ROOT_PASSWORD")


def install_node_exporter() -> None:
    """Install latest node_exporter from GitHub releases and enable systemd."""
    require_root()
    binary = "node_exporter"
    print("installing node_exporter (latest release)")
    github_binary("prometheus/node_exporter", binary)
    unit = f"""[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
ExecStart=/usr/local/bin/{binary}
Restart=always

[Install]
WantedBy=multi-user.target
"""
    write_if_changed(Path(f"/etc/systemd/system/{binary}.service"), unit)
    dest = Path("/usr/local/bin") / binary
    if not dest.is_file():
        print(f"✗ {dest} missing after install")
        raise SystemExit(1)
    service_enable(f"{binary}.service")
    print("✓ node_exporter installed and enabled")
