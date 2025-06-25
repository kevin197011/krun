# 系统性能优化脚本

## 脚本名称
`optimize-system-performance.sh`

## 功能描述
这是一个通用的系统性能优化初始化脚本，支持 Debian/Ubuntu 和 CentOS 9/RHEL 系统的性能调优。

## 主要功能

### 🔧 系统优化项目
1. **内核参数优化**
   - 虚拟内存管理优化
   - 网络性能调优
   - TCP/IP 栈优化
   - 文件系统参数调优
   - 安全参数配置

2. **系统资源限制优化**
   - 文件句柄数限制提升
   - 进程数量限制优化
   - 内存锁定限制配置
   - systemd 服务限制调整

3. **网络性能优化**
   - BBR 拥塞控制算法启用
   - 网络缓冲区大小优化
   - TCP 参数调优

4. **文件系统优化**
   - 挂载选项优化（noatime）
   - 预读参数调整
   - I/O 调度器优化

5. **内存管理优化**
   - 透明大页禁用
   - NUMA 平衡配置
   - 交换分区优化

6. **I/O 调度器优化**
   - SSD 使用 deadline/mq-deadline
   - HDD 使用 cfq/bfq
   - udev 规则持久化

### 🖥️ 平台特定优化

#### CentOS 9/RHEL
- 使用 `dnf` 包管理器
- 启用 EPEL 源
- 配置 `tuned` 性能调优工具
- 设置 `throughput-performance` 配置文件
- 启用 `irqbalance` 中断均衡
- SELinux 完全禁用

#### Debian/Ubuntu
- 使用 `apt` 包管理器
- 配置 CPU 性能调速器
- 启用 `irqbalance` 中断均衡
- AppArmor 优化配置
- 安装性能监控工具

### 📦 安装的工具包
- `htop` - 进程监控
- `iotop` - I/O 监控
- `sysstat` - 系统统计
- `irqbalance` - 中断均衡
- `numactl` - NUMA 控制
- `vim` - 文本编辑器
- 网络诊断工具集

### 🛡️ 安全优化
- 禁用不必要的服务
- 网络安全参数配置
- 内核安全选项启用
- SELinux 完全禁用（提高性能）

## 使用方法

### 直接执行
```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/optimize-system-performance.sh | bash
```

### 通过 krun 工具
```bash
# 查看脚本列表
krun list

# 执行优化脚本（假设是第46号）
krun 46

# 或者直接使用脚本名
krun optimize-system-performance.sh

# 调试模式查看脚本内容
krun optimize-system-performance.sh --debug
```

## 注意事项

### ⚠️ 重要提醒
1. **备份配置**: 脚本会自动备份原始配置文件到 `/root/krun-backup-YYYYMMDD-HHMMSS/`
2. **需要重启**: 执行完成后需要重启系统以使所有更改生效
3. **Root 权限**: 脚本需要管理员权限执行
4. **生产环境**: 建议先在测试环境验证

### 🔧 配置文件位置
- 内核参数: `/etc/sysctl.d/99-performance.conf`
- 系统限制: `/etc/security/limits.d/99-performance.conf`
- systemd 配置: `/etc/systemd/system.conf`
- I/O 调度器: `/etc/udev/rules.d/60-ioschedulers.rules`

### 📊 性能指标改善
执行脚本后，系统在以下方面会有显著改善：
- 网络吞吐量提升
- 文件 I/O 性能优化
- 系统响应延迟降低
- 内存使用效率提高
- CPU 负载均衡改善

## 兼容性

### 支持的操作系统
- ✅ CentOS 9
- ✅ RHEL 9
- ✅ Fedora 35+
- ✅ Debian 11+
- ✅ Ubuntu 20.04+

### 硬件要求
- 最小内存: 1GB
- 推荐内存: 4GB+
- 支持 x86_64 架构

## 故障排除

### 常见问题
1. **脚本执行失败**: 检查网络连接和权限
2. **服务启动失败**: 查看 systemd 日志
3. **性能无改善**: 重启系统后再测试

### 恢复配置
如需恢复原始配置：
```bash
# 查找备份目录
ls -la /root/krun-backup-*/

# 恢复配置文件
cp /root/krun-backup-*/sysctl.conf /etc/
cp /root/krun-backup-*/limits.conf /etc/security/

# 重新加载配置
sysctl -p
```

## 作者信息
- 版权: Copyright (c) 2024 kk
- 许可证: MIT License
- 项目地址: https://github.com/kevin197011/krun