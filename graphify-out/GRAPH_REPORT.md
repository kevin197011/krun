# Graph Report - krun  (2026-07-02)

## Corpus Check
- 88 files · ~45,778 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 740 nodes · 1168 edges · 93 communities (90 shown, 3 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `e74e4756`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]
- [[_COMMUNITY_Community 43|Community 43]]
- [[_COMMUNITY_Community 44|Community 44]]
- [[_COMMUNITY_Community 45|Community 45]]
- [[_COMMUNITY_Community 46|Community 46]]
- [[_COMMUNITY_Community 47|Community 47]]
- [[_COMMUNITY_Community 48|Community 48]]
- [[_COMMUNITY_Community 49|Community 49]]
- [[_COMMUNITY_Community 50|Community 50]]
- [[_COMMUNITY_Community 51|Community 51]]
- [[_COMMUNITY_Community 52|Community 52]]
- [[_COMMUNITY_Community 53|Community 53]]
- [[_COMMUNITY_Community 54|Community 54]]
- [[_COMMUNITY_Community 55|Community 55]]
- [[_COMMUNITY_Community 56|Community 56]]
- [[_COMMUNITY_Community 57|Community 57]]
- [[_COMMUNITY_Community 58|Community 58]]
- [[_COMMUNITY_Community 59|Community 59]]
- [[_COMMUNITY_Community 60|Community 60]]
- [[_COMMUNITY_Community 61|Community 61]]
- [[_COMMUNITY_Community 62|Community 62]]
- [[_COMMUNITY_Community 63|Community 63]]
- [[_COMMUNITY_Community 64|Community 64]]
- [[_COMMUNITY_Community 65|Community 65]]
- [[_COMMUNITY_Community 66|Community 66]]
- [[_COMMUNITY_Community 67|Community 67]]
- [[_COMMUNITY_Community 68|Community 68]]
- [[_COMMUNITY_Community 69|Community 69]]
- [[_COMMUNITY_Community 70|Community 70]]
- [[_COMMUNITY_Community 71|Community 71]]
- [[_COMMUNITY_Community 72|Community 72]]
- [[_COMMUNITY_Community 73|Community 73]]
- [[_COMMUNITY_Community 74|Community 74]]
- [[_COMMUNITY_Community 75|Community 75]]
- [[_COMMUNITY_Community 76|Community 76]]
- [[_COMMUNITY_Community 77|Community 77]]
- [[_COMMUNITY_Community 78|Community 78]]
- [[_COMMUNITY_Community 79|Community 79]]
- [[_COMMUNITY_Community 80|Community 80]]
- [[_COMMUNITY_Community 81|Community 81]]
- [[_COMMUNITY_Community 82|Community 82]]
- [[_COMMUNITY_Community 83|Community 83]]
- [[_COMMUNITY_Community 84|Community 84]]
- [[_COMMUNITY_Community 85|Community 85]]
- [[_COMMUNITY_Community 87|Community 87]]
- [[_COMMUNITY_Community 88|Community 88]]

## God Nodes (most connected - your core abstractions)
1. `krun::check::system_troubleshoot::common()` - 18 edges
2. `krun::check::system_troubleshoot::title()` - 14 edges
3. `Krun - 运维自动化脚本工具集` - 14 edges
4. `krun::check::system_troubleshoot::cmd()` - 13 edges
5. `krun::disk::analyze_cleanup::run_clean()` - 12 edges
6. `krun::install::helm::common()` - 9 edges
7. `krun::disk::analyze_cleanup::has()` - 9 edges
8. `krun::disk::analyze_cleanup::common()` - 9 edges
9. `krun::config::git::common()` - 9 edges
10. `krun::install::git::binary_install()` - 9 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Communities (93 total, 3 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.15
Nodes (32): krun::disk::analyze_cleanup::add_freed(), krun::disk::analyze_cleanup::analyze_targets(), krun::disk::analyze_cleanup::centos(), krun::disk::analyze_cleanup::cleanup_action(), krun::disk::analyze_cleanup::cleanup_docker(), krun::disk::analyze_cleanup::cleanup_journal(), krun::disk::analyze_cleanup::cleanup_old_kernels(), krun::disk::analyze_cleanup::cleanup_package_cache() (+24 more)

### Community 1 - "Community 1"
Cohesion: 0.19
Nodes (27): krun::check::system_troubleshoot::centos(), krun::check::system_troubleshoot::cmd(), krun::check::system_troubleshoot::common(), krun::check::system_troubleshoot::debian(), krun::check::system_troubleshoot::has(), krun::check::system_troubleshoot::hr(), krun::check::system_troubleshoot::mac(), krun::check::system_troubleshoot::now() (+19 more)

### Community 2 - "Community 2"
Cohesion: 0.17
Nodes (28): krun::install::helm::centos(), krun::install::helm::common(), krun::install::helm::configure_proxy(), krun::install::helm::debian(), krun::install::helm::download_file(), krun::install::helm::ensure_in_path(), krun::install::helm::get_github_latest_tag(), krun::install::helm::get_latest_version() (+20 more)

### Community 3 - "Community 3"
Cohesion: 0.23
Nodes (16): krun::install::ansible::centos(), krun::install::ansible::common(), krun::install::ansible::debian(), krun::install::ansible::debian_ubuntu_codename(), krun::install::ansible::enable_epel(), krun::install::ansible::ensure_pip(), krun::install::ansible::ensure_user_local_bin_in_path(), krun::install::ansible::install_argcomplete() (+8 more)

### Community 4 - "Community 4"
Cohesion: 0.20
Nodes (14): krun::optimize::system_performance::backup_configs(), krun::optimize::system_performance::common(), krun::optimize::system_performance::configure_bash_aliases(), krun::optimize::system_performance::configure_git(), krun::optimize::system_performance::configure_limits(), krun::optimize::system_performance::configure_sysctl(), krun::optimize::system_performance::configure_tmux(), krun::optimize::system_performance::configure_tools() (+6 more)

### Community 5 - "Community 5"
Cohesion: 0.27
Nodes (12): krun::install::blackbox_exporter::centos(), krun::install::blackbox_exporter::common(), krun::install::blackbox_exporter::configure_proxy(), krun::install::blackbox_exporter::create_service(), krun::install::blackbox_exporter::debian(), krun::install::blackbox_exporter::get_latest_version(), krun::install::blackbox_exporter::get_system_info(), krun::install::blackbox_exporter::mac() (+4 more)

### Community 6 - "Community 6"
Cohesion: 0.36
Nodes (11): krun::install::k9s::centos(), krun::install::k9s::debian(), krun::install::k9s::download_file(), krun::install::k9s::get_latest_version(), krun::install::k9s::install_from_package(), krun::install::k9s::install_from_tarball(), krun::install::k9s::mac(), krun::install::k9s::map_arch() (+3 more)

### Community 7 - "Community 7"
Cohesion: 0.27
Nodes (8): krun::config::acme::install(), krun::config::acme::install_cert(), krun::config::acme::issue(), krun::config::acme::list(), krun::config::acme::renew(), krun::config::acme::revoke(), krun::config::acme::run(), krun::config::acme::usage()

### Community 8 - "Community 8"
Cohesion: 0.29
Nodes (9): krun::install::jdk8::centos(), krun::install::jdk8::common(), krun::install::jdk8::debian(), krun::install::jdk8::download_tar(), krun::install::jdk8::export_session_env(), krun::install::jdk8::read_wgetrc_proxy(), krun::install::jdk8::resolve_proxy(), krun::install::jdk8::resolve_tar() (+1 more)

### Community 9 - "Community 9"
Cohesion: 0.31
Nodes (9): krun::check::ip_quality::centos(), krun::check::ip_quality::common(), krun::check::ip_quality::debian(), krun::check::ip_quality::evaluate(), krun::check::ip_quality::mac(), krun::check::ip_quality::ping_test(), krun::check::ip_quality::progress(), krun::check::ip_quality::test_node() (+1 more)

### Community 10 - "Community 10"
Cohesion: 0.33
Nodes (9): krun::config::git::centos(), krun::config::git::common(), krun::config::git::configure_aliases(), krun::config::git::configure_global_settings(), krun::config::git::configure_ssh_key(), krun::config::git::configure_user(), krun::config::git::debian(), krun::config::git::display_summary() (+1 more)

### Community 11 - "Community 11"
Cohesion: 0.42
Nodes (9): krun::install::filebeat::centos(), krun::install::filebeat::config(), krun::install::filebeat::debian(), krun::install::filebeat::detect_log_type(), krun::install::filebeat::extract_project_module(), krun::install::filebeat::get_node_ip(), krun::install::filebeat::mac(), krun::install::filebeat::start() (+1 more)

### Community 12 - "Community 12"
Cohesion: 0.42
Nodes (9): krun::install::git::binary_install(), krun::install::git::centos(), krun::install::git::common(), krun::install::git::configure_git(), krun::install::git::debian(), krun::install::git::get_latest_version(), krun::install::git::get_system_info(), krun::install::git::mac() (+1 more)

### Community 13 - "Community 13"
Cohesion: 0.31
Nodes (9): krun::install::node_exporter::centos(), krun::install::node_exporter::common(), krun::install::node_exporter::create_service(), krun::install::node_exporter::debian(), krun::install::node_exporter::get_latest_version(), krun::install::node_exporter::get_system_info(), krun::install::node_exporter::mac(), krun::install::node_exporter::manual_install() (+1 more)

### Community 14 - "Community 14"
Cohesion: 0.38
Nodes (8): krun::install::centos(), krun::install::debian(), krun::install::install_binary(), krun::install::install_deps_centos(), krun::install::install_deps_debian(), krun::install::install_deps_mac(), krun::install::install_from_package(), krun::install::mac()

### Community 15 - "Community 15"
Cohesion: 0.20
Nodes (10): code:bash (# 重新运行安装脚本即可（会自动下载最新版本）), code:bash (# 使用 krun 工具查看脚本列表), code:bash (# 删除安装目录), code:bash (# 是的，install.sh 会自动检测并安装所需依赖：), Q: 如何卸载 krun？, Q: 如何更新 krun 工具？, Q: 如何查看所有可用脚本？, Q: 安装脚本会自动安装依赖吗？ (+2 more)

### Community 16 - "Community 16"
Cohesion: 0.20
Nodes (9): code:block1 (______), Krun - 运维自动化脚本工具集, 支持平台, 核心特性, 注意事项, 相关资源, 许可证, 贡献指南 (+1 more)

### Community 17 - "Community 17"
Cohesion: 0.36
Nodes (8): krun::install::rclone::centos(), krun::install::rclone::common(), krun::install::rclone::create_config(), krun::install::rclone::create_service(), krun::install::rclone::debian(), krun::install::rclone::get_latest_version(), krun::install::rclone::get_system_info(), krun::install::rclone::mac()

### Community 18 - "Community 18"
Cohesion: 0.36
Nodes (8): krun::install::redis::centos(), krun::install::redis::common(), krun::install::redis::configure_redis(), krun::install::redis::debian(), krun::install::redis::mac(), krun::install::redis::manage_service(), krun::install::redis::manual_install(), krun::install::redis::test_redis()

### Community 19 - "Community 19"
Cohesion: 0.33
Nodes (7): krun::update::vagrant_box::centos(), krun::update::vagrant_box::check_vagrant(), krun::update::vagrant_box::common(), krun::update::vagrant_box::debian(), krun::update::vagrant_box::mac(), krun::update::vagrant_box::show_status(), krun::update::vagrant_box::update_box()

### Community 20 - "Community 20"
Cohesion: 0.22
Nodes (9): code:bash (# 1. 安装 krun 工具), code:bash (# 修复 Rocky Linux 9 的 IPv6 源导致的包管理器问题), code:bash (krun install-docker.sh), code:bash (# 自动格式化并挂载数据盘到 /data), Kubernetes 环境搭建, Rocky Linux 9 修复 IPv6 源问题, 使用示例, 新服务器初始化 (+1 more)

### Community 21 - "Community 21"
Cohesion: 0.33
Nodes (5): krun::config::centos7_repo::centos(), krun::config::centos7_repo::install_endpoint_repo(), krun::config::centos7_repo::prune_legacy_repos(), krun::config::centos7_repo::refresh_yum_cache(), krun::config::centos7_repo::write_devops_repo()

### Community 22 - "Community 22"
Cohesion: 0.44
Nodes (7): krun::install::asdf::centos(), krun::install::asdf::common(), krun::install::asdf::configure_shell(), krun::install::asdf::debian(), krun::install::asdf::get_latest_version(), krun::install::asdf::mac(), krun::install::asdf::verify_installation()

### Community 23 - "Community 23"
Cohesion: 0.39
Nodes (7): krun::install::crane::centos(), krun::install::crane::common(), krun::install::crane::debian(), krun::install::crane::get_latest_version(), krun::install::crane::get_system_info(), krun::install::crane::mac(), krun::install::crane::sudo()

### Community 24 - "Community 24"
Cohesion: 0.44
Nodes (7): krun::install::rbenv::centos(), krun::install::rbenv::common(), krun::install::rbenv::configure_shell(), krun::install::rbenv::debian(), krun::install::rbenv::get_latest_version(), krun::install::rbenv::mac(), krun::install::rbenv::verify_installation()

### Community 25 - "Community 25"
Cohesion: 0.39
Nodes (7): krun::install::tinyproxy::centos(), krun::install::tinyproxy::common(), krun::install::tinyproxy::configure(), krun::install::tinyproxy::create_config(), krun::install::tinyproxy::debian(), krun::install::tinyproxy::mac(), krun::install::tinyproxy::manage_service()

### Community 26 - "Community 26"
Cohesion: 0.25
Nodes (8): 🔄 Git 工具类（2个）, 📝 其他工具（3个）, 🚀 开发环境安装类（20个）, 📋 系统配置类（17个）, 脚本列表（66+ 个）, 🔧 运维工具安装类（15个）, 🛠️ 运维脚本类（8个）, 🎛️ 面板和管理工具（2个）

### Community 27 - "Community 27"
Cohesion: 0.43
Nodes (6): krun::install::docker::centos(), krun::install::docker::common(), krun::install::docker::common_mac(), krun::install::docker::configure_service(), krun::install::docker::debian(), krun::install::docker::mac()

### Community 28 - "Community 28"
Cohesion: 0.46
Nodes (6): krun::install::golang::centos(), krun::install::golang::common(), krun::install::golang::debian(), krun::install::golang::mac(), krun::install::golang::manual_install(), krun::install::golang::verify_installation()

### Community 29 - "Community 29"
Cohesion: 0.43
Nodes (6): krun::install::oh_my_zsh::centos(), krun::install::oh_my_zsh::common(), krun::install::oh_my_zsh::configure_zshrc(), krun::install::oh_my_zsh::debian(), krun::install::oh_my_zsh::install_plugins(), krun::install::oh_my_zsh::mac()

### Community 30 - "Community 30"
Cohesion: 0.50
Nodes (6): krun::install::openjdk::centos(), krun::install::openjdk::common(), krun::install::openjdk::configure_java_home(), krun::install::openjdk::debian(), krun::install::openjdk::mac(), krun::install::openjdk::manual_install()

### Community 31 - "Community 31"
Cohesion: 0.46
Nodes (6): krun::install::vagrant-virtualbox::centos(), krun::install::vagrant-virtualbox::common(), krun::install::vagrant-virtualbox::debian(), krun::install::vagrant-virtualbox::install_boxes(), krun::install::vagrant-virtualbox::mac(), krun::install::vagrant-virtualbox::verify_installation()

### Community 32 - "Community 32"
Cohesion: 0.29
Nodes (7): code:bash (# 一键安装（自动检测平台并安装依赖）), code:bash (# Docker 安装), code:bash (# 克隆仓库), 快速开始, 方式一：安装 Krun 工具（推荐）, 方式三：本地使用, 方式二：直接执行脚本

### Community 33 - "Community 33"
Cohesion: 0.48
Nodes (5): krun::apply::asdf::centos(), krun::apply::asdf::common(), krun::apply::asdf::debian(), krun::apply::asdf::install_common_tools(), krun::apply::asdf::mac()

### Community 34 - "Community 34"
Cohesion: 0.48
Nodes (5): krun::check::system_baseline::centos(), krun::check::system_baseline::check(), krun::check::system_baseline::common(), krun::check::system_baseline::debian(), krun::check::system_baseline::mac()

### Community 35 - "Community 35"
Cohesion: 0.48
Nodes (5): krun::config::rakefile::centos(), krun::config::rakefile::common(), krun::config::rakefile::debian(), krun::config::rakefile::install_gems(), krun::config::rakefile::mac()

### Community 36 - "Community 36"
Cohesion: 0.57
Nodes (5): krun::config::ruby_http::centos(), krun::config::ruby_http::common(), krun::config::ruby_http::debian(), krun::config::ruby_http::ensure_gems(), krun::config::ruby_http::mac()

### Community 37 - "Community 37"
Cohesion: 0.48
Nodes (5): krun::config::ssh_authorized_keys::append_key_for_user(), krun::config::ssh_authorized_keys::centos(), krun::config::ssh_authorized_keys::common(), krun::config::ssh_authorized_keys::debian(), krun::config::ssh_authorized_keys::mac()

### Community 38 - "Community 38"
Cohesion: 0.52
Nodes (5): krun::install::awscli::centos(), krun::install::awscli::common(), krun::install::awscli::debian(), krun::install::awscli::mac(), krun::install::awscli::verify_installation()

### Community 39 - "Community 39"
Cohesion: 0.52
Nodes (5): krun::install::elixir::centos(), krun::install::elixir::common(), krun::install::elixir::debian(), krun::install::elixir::mac(), krun::install::elixir::verify_installation()

### Community 40 - "Community 40"
Cohesion: 0.57
Nodes (5): krun::install::ffmpeg::centos(), krun::install::ffmpeg::common(), krun::install::ffmpeg::debian(), krun::install::ffmpeg::mac(), krun::install::ffmpeg::static_install()

### Community 41 - "Community 41"
Cohesion: 0.52
Nodes (5): krun::install::gcloud::centos(), krun::install::gcloud::common(), krun::install::gcloud::debian(), krun::install::gcloud::mac(), krun::install::gcloud::verify_installation()

### Community 42 - "Community 42"
Cohesion: 0.48
Nodes (5): krun::install::python3::centos(), krun::install::python3::common(), krun::install::python3::debian(), krun::install::python3::mac(), krun::install::python3::verify_installation()

### Community 43 - "Community 43"
Cohesion: 0.48
Nodes (5): krun::install::ruby::centos(), krun::install::ruby::common(), krun::install::ruby::debian(), krun::install::ruby::mac(), krun::install::ruby::verify_installation()

### Community 44 - "Community 44"
Cohesion: 0.53
Nodes (4): krun::config::cursor::centos(), krun::config::cursor::common(), krun::config::cursor::debian(), krun::config::cursor::mac()

### Community 45 - "Community 45"
Cohesion: 0.47
Nodes (3): krun::config::disk-data::centos(), krun::config::disk-data::common(), krun::config::disk-data::debian()

### Community 46 - "Community 46"
Cohesion: 0.53
Nodes (4): krun::config::elasticsearch::centos(), krun::config::elasticsearch::common(), krun::config::elasticsearch::debian(), krun::config::elasticsearch::mac()

### Community 47 - "Community 47"
Cohesion: 0.47
Nodes (3): krun::config::fstab::centos(), krun::config::fstab::common(), krun::config::fstab::debian()

### Community 48 - "Community 48"
Cohesion: 0.53
Nodes (4): krun::config::locales::centos(), krun::config::locales::common(), krun::config::locales::debian(), krun::config::locales::mac()

### Community 49 - "Community 49"
Cohesion: 0.53
Nodes (4): krun::config::proxy::centos(), krun::config::proxy::common(), krun::config::proxy::debian(), krun::config::proxy::mac()

### Community 51 - "Community 51"
Cohesion: 0.53
Nodes (4): krun::config::ssh::centos(), krun::config::ssh::common(), krun::config::ssh::debian(), krun::config::ssh::mac()

### Community 52 - "Community 52"
Cohesion: 0.47
Nodes (3): krun::config::system_baseline::centos(), krun::config::system_baseline::common(), krun::config::system_baseline::debian()

### Community 53 - "Community 53"
Cohesion: 0.53
Nodes (4): krun::config::timezone::centos(), krun::config::timezone::common(), krun::config::timezone::debian(), krun::config::timezone::mac()

### Community 54 - "Community 54"
Cohesion: 0.53
Nodes (4): krun::config::vagrant-ssh::centos(), krun::config::vagrant-ssh::common(), krun::config::vagrant-ssh::debian(), krun::config::vagrant-ssh::mac()

### Community 55 - "Community 55"
Cohesion: 0.47
Nodes (3): krun::config::vm::centos(), krun::config::vm::common(), krun::config::vm::debian()

### Community 56 - "Community 56"
Cohesion: 0.53
Nodes (4): krun::crane::copy::centos(), krun::crane::copy::common(), krun::crane::copy::debian(), krun::crane::copy::mac()

### Community 57 - "Community 57"
Cohesion: 0.53
Nodes (4): krun::delete::video::centos(), krun::delete::video::common(), krun::delete::video::debian(), krun::delete::video::mac()

### Community 58 - "Community 58"
Cohesion: 0.53
Nodes (4): krun::deploy::sshkey::centos(), krun::deploy::sshkey::common(), krun::deploy::sshkey::debian(), krun::deploy::sshkey::mac()

### Community 59 - "Community 59"
Cohesion: 0.47
Nodes (3): krun::disable::firewall_selinux::centos(), krun::disable::firewall_selinux::common(), krun::disable::firewall_selinux::debian()

### Community 60 - "Community 60"
Cohesion: 0.53
Nodes (4): krun::hello::world::centos(), krun::hello::world::common(), krun::hello::world::debian(), krun::hello::world::mac()

### Community 61 - "Community 61"
Cohesion: 0.47
Nodes (3): krun::install::1panel::centos(), krun::install::1panel::common(), krun::install::1panel::debian()

### Community 62 - "Community 62"
Cohesion: 0.53
Nodes (4): krun::install::aapanel::centos(), krun::install::aapanel::common(), krun::install::aapanel::debian(), krun::install::aapanel::mac()

### Community 63 - "Community 63"
Cohesion: 0.53
Nodes (4): krun::install::aliyun-cli::centos(), krun::install::aliyun-cli::common(), krun::install::aliyun-cli::debian(), krun::install::aliyun-cli::mac()

### Community 64 - "Community 64"
Cohesion: 0.53
Nodes (4): krun::install::base_packages::centos(), krun::install::base_packages::common(), krun::install::base_packages::debian(), krun::install::base_packages::mac()

### Community 65 - "Community 65"
Cohesion: 0.47
Nodes (3): krun::install::cpanm::centos(), krun::install::cpanm::debian(), krun::install::cpanm::sudo()

### Community 66 - "Community 66"
Cohesion: 0.53
Nodes (4): krun::install::cursor_cli::centos(), krun::install::cursor_cli::common(), krun::install::cursor_cli::debian(), krun::install::cursor_cli::mac()

### Community 67 - "Community 67"
Cohesion: 0.53
Nodes (4): krun::install::devbox::centos(), krun::install::devbox::common(), krun::install::devbox::debian(), krun::install::devbox::mac()

### Community 68 - "Community 68"
Cohesion: 0.47
Nodes (3): krun::install::fonts_nerd::centos(), krun::install::fonts_nerd::debian(), krun::install::fonts_nerd::install_linux()

### Community 69 - "Community 69"
Cohesion: 0.53
Nodes (4): krun::install::geoipupdate::centos(), krun::install::geoipupdate::common(), krun::install::geoipupdate::debian(), krun::install::geoipupdate::mac()

### Community 70 - "Community 70"
Cohesion: 0.47
Nodes (3): krun::install::kind::centos(), krun::install::kind::common(), krun::install::kind::debian()

### Community 71 - "Community 71"
Cohesion: 0.53
Nodes (4): krun::install::lsyncd::centos(), krun::install::lsyncd::common(), krun::install::lsyncd::debian(), krun::install::lsyncd::mac()

### Community 72 - "Community 72"
Cohesion: 0.53
Nodes (4): krun::install::maven::centos(), krun::install::maven::common(), krun::install::maven::debian(), krun::install::maven::mac()

### Community 73 - "Community 73"
Cohesion: 0.53
Nodes (4): krun::install::mc::centos(), krun::install::mc::common(), krun::install::mc::debian(), krun::install::mc::mac()

### Community 74 - "Community 74"
Cohesion: 0.53
Nodes (4): krun::install::nginx::centos(), krun::install::nginx::common(), krun::install::nginx::debian(), krun::install::nginx::mac()

### Community 75 - "Community 75"
Cohesion: 0.53
Nodes (4): krun::install::percona_toolkit::centos(), krun::install::percona_toolkit::common(), krun::install::percona_toolkit::debian(), krun::install::percona_toolkit::mac()

### Community 76 - "Community 76"
Cohesion: 0.53
Nodes (4): krun::install::puppet_bolt::centos(), krun::install::puppet_bolt::common(), krun::install::puppet_bolt::debian(), krun::install::puppet_bolt::mac()

### Community 77 - "Community 77"
Cohesion: 0.53
Nodes (4): krun::install::salt_master::centos(), krun::install::salt_master::common(), krun::install::salt_master::debian(), krun::install::salt_master::mac()

### Community 78 - "Community 78"
Cohesion: 0.53
Nodes (4): krun::install::salt_minion::centos(), krun::install::salt_minion::common(), krun::install::salt_minion::debian(), krun::install::salt_minion::mac()

### Community 79 - "Community 79"
Cohesion: 0.53
Nodes (4): krun::install::spacevim::centos(), krun::install::spacevim::common(), krun::install::spacevim::debian(), krun::install::spacevim::mac()

### Community 80 - "Community 80"
Cohesion: 0.53
Nodes (4): krun::install::vim::centos(), krun::install::vim::common(), krun::install::vim::debian(), krun::install::vim::mac()

### Community 81 - "Community 81"
Cohesion: 0.53
Nodes (4): krun::install::zsh::centos(), krun::install::zsh::common(), krun::install::zsh::debian(), krun::install::zsh::mac()

### Community 82 - "Community 82"
Cohesion: 0.53
Nodes (4): krun::reset::git-history::centos(), krun::reset::git-history::common(), krun::reset::git-history::debian(), krun::reset::git-history::mac()

### Community 83 - "Community 83"
Cohesion: 0.60
Nodes (3): krun::deploy::node_exporter::centos(), krun::deploy::node_exporter::common(), krun::deploy::node_exporter::debian()

### Community 84 - "Community 84"
Cohesion: 0.50
Nodes (4): 主要功能, 服务部署, 系统配置, 运维工具

### Community 85 - "Community 85"
Cohesion: 0.50
Nodes (4): code:bash (# 参考模板创建), 创建新脚本, 开发者指南, 脚本标准格式

## Knowledge Gaps
- **33 isolated node(s):** `files`, `TEST_NODES`, `code:block1 (______)`, `核心特性`, `系统配置` (+28 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Krun - 运维自动化脚本工具集` connect `Community 16` to `Community 32`, `Community 15`, `Community 84`, `Community 85`, `Community 20`, `Community 26`?**
  _High betweenness centrality (0.004) - this node is a cross-community bridge._
- **Why does `常见问题` connect `Community 15` to `Community 16`?**
  _High betweenness centrality (0.002) - this node is a cross-community bridge._
- **Why does `使用示例` connect `Community 20` to `Community 16`?**
  _High betweenness centrality (0.001) - this node is a cross-community bridge._
- **What connects `files`, `TEST_NODES`, `code:block1 (______)` to the rest of the system?**
  _33 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.1495798319327731 - nodes in this community are weakly interconnected._