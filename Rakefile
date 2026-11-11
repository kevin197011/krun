# frozen_string_literal: true

# Copyright (c) 2025 kk
# MIT License: https://opensource.org/licenses/MIT

require 'bundler/setup'
require 'shellwords'
require 'fileutils'
require 'kk/git/rake_tasks'

RAW_BASE = 'https://raw.githubusercontent.com/kevin197011/krun/main'
COMMANDS_MD = 'docs/COMMANDS.md'

task default: %w[push]

desc 'Build Go CLI into bin/krun'
task :build do
  sh 'mkdir -p bin'
  sh 'go build -ldflags "-s -w -X main.version=dev -X main.commit=local" -o bin/krun ./cmd/krun'
end

namespace :docs do
  desc 'Regenerate docs/COMMANDS.md from lib/sh + lib/ps1'
  task :commands do
    write_commands_md!
  end
end

desc 'Commit + push, then bump and push a new v* tag (triggers Release)'
task push: 'docs:commands' do
  # kk-git defaults to `git pull --ff-only`, which fails on diverged branches.
  ENV['KK_GIT_PULL_ARGS'] ||= '--no-rebase'

  # Ensure regenerated catalog is included in the upcoming commit.
  sh "git add -- #{Shellwords.escape(COMMANDS_MD)}"

  head_before = `git rev-parse HEAD`.strip

  generator = lambda do
    Rake::Task['git:auto_commit'].reenable
    Rake::Task['git:auto_commit'].invoke
    ENV.fetch('KK_GIT_COMMIT_MESSAGE', '').to_s
  end

  result = KKGit::GitOps.auto_commit_push!(commit_message_generator: generator)
  head_after = `git rev-parse HEAD`.strip

  if ENV['SKIP_TAG'] == '1'
    puts 'SKIP_TAG=1 — not tagging'
    next
  end

  # Tag only when this push produced a new commit (叠加版本).
  unless result == :committed_and_synced || head_before != head_after
    puts "No new commit (#{result}) — skip tag"
    next
  end

  tag = next_semver_tag
  msg = "Release #{tag}"
  sh "git tag -a #{Shellwords.escape(tag)} -m #{Shellwords.escape(msg)}"
  sh "git push #{Shellwords.escape(KKGit::GitOps.remote)} #{Shellwords.escape(tag)}"
  puts "Tagged and pushed #{tag}"
end

def write_commands_md!
  sh_files = Dir['lib/sh/*.sh'].map { |f| File.basename(f) }.sort
  ps1_files = Dir['lib/ps1/*.ps1'].map { |f| File.basename(f) }.sort

  sh_groups = Hash.new { |h, k| h[k] = [] }
  sh_files.each { |n| sh_groups[group_sh(n)] << n }

  ps1_groups = Hash.new { |h, k| h[k] = [] }
  ps1_files.each { |n| ps1_groups[group_ps1(n)] << n }

  lines = []
  lines << '# Krun 快捷命令清单'
  lines << ''
  lines << '复制即用（curl / irm）。'
  lines << ''
  lines << '刷新本页：`rake docs:commands`'
  lines << ''
  lines << '## 部署 CLI'
  lines << ''
  lines << '安装 / **覆盖更新** / 卸载。重复执行安装会写回已有路径并清其它残留。'
  lines << ''
  lines << '### Linux / macOS'
  lines << ''
  lines << '```bash'
  lines << "# 安装或覆盖更新到最新 Release"
  lines << "curl -fsSL #{RAW_BASE}/deploy.sh | bash"
  lines << '# 钉版本'
  lines << "KRUN_VERSION=v2.2.0 curl -fsSL #{RAW_BASE}/deploy.sh | bash"
  lines << '# 卸载'
  lines << "curl -fsSL #{RAW_BASE}/deploy.sh | bash -s -- --uninstall"
  lines << '```'
  lines << ''
  lines << '### Windows'
  lines << ''
  lines << '```powershell'
  lines << '# 安装或覆盖更新到最新 Release'
  lines << "irm #{RAW_BASE}/deploy.ps1 | iex"
  lines << '# 钉版本'
  lines << "$env:KRUN_VERSION='v2.2.0'; irm #{RAW_BASE}/deploy.ps1 | iex"
  lines << '# 卸载'
  lines << "$env:KRUN_ACTION='uninstall'; irm #{RAW_BASE}/deploy.ps1 | iex"
  lines << '```'
  lines << ''
  lines << '## Shell（Linux / macOS）'
  lines << ''
  lines << '通用：'
  lines << ''
  lines << '```bash'
  lines << "curl -fsSL #{RAW_BASE}/lib/sh/<name>.sh | sudo bash"
  lines << '```'
  lines << ''

  %w[安装 配置 检查 部署 其它].each do |group|
    items = sh_groups[group]
    next if items.empty?

    lines << "### #{group}"
    lines << ''
    items.each do |name|
      lines << "#### `#{name}`"
      lines << ''
      lines << '```bash'
      lines << "curl -fsSL #{RAW_BASE}/lib/sh/#{name} | sudo bash"
      lines << '```'
      lines << ''
    end
  end

  lines << '## PowerShell（Windows）'
  lines << ''
  lines << '通用（管理员）：'
  lines << ''
  lines << '```powershell'
  lines << "irm #{RAW_BASE}/lib/ps1/<name>.ps1 | iex"
  lines << '```'
  lines << ''
  lines << "强制重装：`$env:FORCE_INSTALL='true'` 或 `-Force`。"
  lines << ''

  %w[安装 配置 其它].each do |group|
    items = ps1_groups[group]
    next if items.empty?

    lines << "### #{group}"
    lines << ''
    items.each do |name|
      lines << "#### `#{name}`"
      lines << ''
      lines << '```powershell'
      lines << "irm #{RAW_BASE}/lib/ps1/#{name} | iex"
      lines << '```'
      lines << ''
    end
  end

  lines << '## 发布'
  lines << ''
  lines << '```bash'
  lines << 'ruby push.rb                 # 提交 + 推送 + 自动 v* tag（patch+1）'
  lines << 'KRUN_BUMP=minor ruby push.rb'
  lines << 'SKIP_TAG=1 ruby push.rb'
  lines << 'rake build                   # 本地编译 bin/krun'
  lines << 'rake docs:commands           # 刷新本清单'
  lines << '```'
  lines << ''

  FileUtils.mkdir_p(File.dirname(COMMANDS_MD))
  File.write(COMMANDS_MD, "#{lines.join("\n")}\n")
  puts "wrote #{COMMANDS_MD} (#{sh_files.size} sh + #{ps1_files.size} ps1)"
end

def group_sh(name)
  return '安装' if name.start_with?('install_')
  return '配置' if name.start_with?('config_')
  return '检查' if name.start_with?('check_')
  return '部署' if name.start_with?('deploy_')

  '其它'
end

def group_ps1(name)
  return '安装' if name.start_with?('install_')
  return '配置' if name.start_with?('config_', 'disable_')

  '其它'
end

def next_semver_tag
  bump = (ENV['KRUN_BUMP'] || 'patch').downcase
  abort "KRUN_BUMP must be major|minor|patch (got #{bump})" unless %w[major minor patch].include?(bump)

  tags = `git tag -l 'v*'`.split("\n").filter_map do |t|
    m = t.match(/\Av(\d+)\.(\d+)\.(\d+)\z/)
    next unless m

    [m[1].to_i, m[2].to_i, m[3].to_i]
  end
  major, minor, patch = tags.max || [1, 0, 0]

  case bump
  when 'major'
    major += 1
    minor = 0
    patch = 0
  when 'minor'
    minor += 1
    patch = 0
  else
    patch += 1
  end

  format('v%d.%d.%d', major, minor, patch)
end
