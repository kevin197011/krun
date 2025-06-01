#!/usr/bin/env ruby
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

class Krun
  VERSION = '2.0 (Ruby)'

  def run(args)
    command = args[0] || 'help'

    case command
    when 'list'
      list_beautiful
    when 'version'
      puts "Krun Multi-Language Script Runner v#{VERSION}"
      puts 'Copyright (c) 2023 kk'
      puts 'MIT License'
    when 'help'
      puts 'Krun Multi-Language Script Runner'
      puts ''
      puts 'Usage:'
      puts '  krun list       - List all scripts'
      puts '  krun version    - Show version'
      puts '  krun help       - Show help'
    else
      puts "Error: Unknown command '#{command}'"
      puts "Use 'krun help' for usage information"
    end
  end

  private

  def list_beautiful
    puts '🚀 Krun Multi-Language Script Collection'
    puts '=' * 50
    puts ''
    puts '📊 This is a demo list display'
    puts '📁 Categories: 6'
    puts ''

    # Demo categories with icons
    categories = [
      { icon: '🐚', name: 'SHELL', count: 25, scripts: ['hello-world.sh', 'install-docker.sh', 'config-system.sh'] },
      { icon: '🐍', name: 'PYTHON', count: 8, scripts: ['install-python3.py', 'setup-venv.py'] },
      { icon: '💎', name: 'RUBY', count: 5, scripts: ['install-ruby.rb', 'config-rails.rb'] },
      { icon: '🐪', name: 'PERL', count: 3, scripts: ['backup-files.pl', 'parse-logs.pl'] },
      { icon: '🟨', name: 'JAVASCRIPT', count: 4, scripts: ['build-assets.js', 'deploy-app.js'] },
      { icon: '📄', name: 'OTHER', count: 2, scripts: ['analysis.r', 'migrate.sql'] }
    ]

    num = 1
    categories.each do |cat|
      puts "#{cat[:icon]} #{cat[:name]} Scripts (#{cat[:count]} files)"
      puts '─' * 40
      cat[:scripts].each do |script|
        puts "    [#{num.to_s.rjust(2)}] #{script}"
        num += 1
      end
      puts ''
    end

    puts '💡 Usage: krun <number> or krun <script_name>'
    puts '🔍 Debug: krun <number> --debug'
    puts '=' * 50
  end
end

# Main execution
if __FILE__ == $0
  krun = Krun.new
  krun.run(ARGV)
end
