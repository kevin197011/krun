"""Package and special installers."""

from __future__ import annotations

import os
import subprocess

from krun_common import (
    curl_pipe,
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
        run(
            f"install -d /etc/apt/keyrings && curl -fsSL https://download.docker.com/linux/{dist}/gpg "
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
    run(["groupadd", "docker"], check=False)
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
    run(
        f"curl -fsSL https://github.com/saltstack/salt-bootstrap/releases/latest/download/bootstrap-salt.sh | sh -s -- stable {flag}".strip(),
        shell=True,
    )
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
        run("curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip -o /tmp/aws.zip && unzip -qo /tmp/aws.zip -d /tmp && /tmp/aws/install", shell=True)
    else:
        install_packages(rhel=["awscli"], deb=["awscli"])
    print("✓ awscli done")


def install_cloud_cli(vendor: str) -> None:
    require_root()
    if vendor == "gcloud":
        curl_pipe("https://sdk.cloud.google.com", shell="bash")
    elif vendor == "aliyun":
        run("curl -fsSL https://aliyuncli.alicdn.com/aliyun-cli-linux-latest-amd64.tgz | tar xz -C /usr/local/bin", shell=True)
    print(f"✓ {vendor} cli done")


def install_devbox() -> None:
    curl_pipe("https://get.jetpack.io/devbox", shell="bash")


def install_cursor_cli() -> None:
    curl_pipe("https://cursor.com/install", shell="bash")


def install_oh_my_zsh() -> None:
    run('sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended', shell=True)


def install_spacevim() -> None:
    curl_pipe("https://spacevim.org/install.sh")


def install_kssh() -> None:
    if platform() != "mac":
        print("✗ kssh is macOS only")
        raise SystemExit(1)
    run("git clone https://github.com/kevin197011/kssh.git ~/.kssh && cd ~/.kssh && bundle install", shell=True)
