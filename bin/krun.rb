#!/usr/bin/env ruby
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

require 'net/http'
require 'json'
require 'uri'
require 'tempfile'
require 'fileutils'

class Krun
  VERSION = '2.0 (Ruby)'
  BASE_URL = ENV['KRUN_BASE_URL'] || 'https://raw.githubusercontent.com/kevin197011/krun/main'
  USER_AGENT = ENV['KRUN_USER_AGENT'] || "Krun/#{VERSION} (Ruby)"

  # Language mappings with interpreters and emojis
  LANGUAGE_MAP = {
    '.sh' => { interpreters: %w[bash sh], emoji: '🐚', name: 'SHELL' },
    '.bash' => { interpreters: ['bash'], emoji: '🐚', name: 'SHELL' },
    '.zsh' => { interpreters: %w[zsh bash], emoji: '🐚', name: 'SHELL' },
    '.fish' => { interpreters: %w[fish bash], emoji: '🐚', name: 'SHELL' },
    '.py' => { interpreters: %w[python3 python], emoji: '🐍', name: 'PYTHON' },
    '.python' => { interpreters: %w[python3 python], emoji: '🐍', name: 'PYTHON' },
    '.rb' => { interpreters: ['ruby'], emoji: '💎', name: 'RUBY' },
    '.ruby' => { interpreters: ['ruby'], emoji: '💎', name: 'RUBY' },
    '.pl' => { interpreters: ['perl'], emoji: '🐪', name: 'PERL' },
    '.perl' => { interpreters: ['perl'], emoji: '🐪', name: 'PERL' },
    '.js' => { interpreters: ['node'], emoji: '🟨', name: 'JAVASCRIPT' },
    '.javascript' => { interpreters: ['node'], emoji: '🟨', name: 'JAVASCRIPT' },
    '.lua' => { interpreters: ['lua'], emoji: '🌙', name: 'LUA' },
    '.r' => { interpreters: ['Rscript'], emoji: '📊', name: 'R' },
    '.R' => { interpreters: ['Rscript'], emoji: '📊', name: 'R' },
    '.php' => { interpreters: ['php'], emoji: '🐘', name: 'PHP' },
    '.swift' => { interpreters: ['swift'], emoji: '🦉', name: 'SWIFT' },
    '.groovy' => { interpreters: ['groovy'], emoji: '☕', name: 'GROOVY' },
    '.scala' => { interpreters: ['scala'], emoji: '🎯', name: 'SCALA' },
    '.ps1' => { interpreters: %w[powershell pwsh], emoji: '💻', name: 'POWERSHELL' }
  }.freeze

  def initialize
    @debug = false
    @http_client = detect_http_client
    @scripts_cache = nil
  end

  def run(args)
    return show_help if args.empty?

    @debug = args.include?('--debug')
    command = args.reject { |arg| arg.start_with?('--') }.first

    case command
    when 'list'
      list_scripts
    when 'status'
      show_status
    when 'languages'
      show_languages
    when 'version'
      show_version
    when 'help'
      show_help
    when /^\d+$/
      execute_by_number(command.to_i, @debug)
    else
      if command
        execute_by_name(command, @debug)
      else
        show_help
      end
    end
  rescue Interrupt
    puts "\n❌ Execution interrupted by user"
    exit(130)
  rescue StandardError => e
    puts "❌ Error: #{e.message}"
    puts e.backtrace.first(3).join("\n") if @debug
    exit(1)
  end

  private

  def detect_http_client
    return 'curl' if command_exists?('curl')
    return 'wget' if command_exists?('wget')

    raise 'No HTTP client found. Please install curl or wget.'
  end

  def fetch_url(url)
    result = case @http_client
             when 'curl'
               `curl -fsSL "#{url}" 2>/dev/null`
             when 'wget'
               `wget -qO- "#{url}" 2>/dev/null`
             end

    raise "Failed to fetch #{url}" unless $?.success?

    result
  end

  def get_scripts_list
    @scripts_cache ||= begin
      scripts_data = fetch_url("#{BASE_URL}/resources/krun.json")
      JSON.parse(scripts_data)
    rescue JSON::ParserError => e
      puts "Error parsing scripts list: #{e.message}"
      exit(1)
    rescue StandardError => e
      puts "Error fetching scripts list: #{e.message}"
      exit(1)
    end
  end

  def list_scripts
    scripts = get_scripts_list
    return if scripts.empty?

    # Group scripts by language
    grouped_scripts = group_scripts_by_language(scripts)
    total_scripts = scripts.length
    categories_count = grouped_scripts.keys.length

    puts '🚀 Krun Multi-Language Script Collection'
    puts '=' * 50
    puts ''
    puts "📊 Total Scripts: #{total_scripts}"
    puts "📁 Categories: #{categories_count}"
    puts ''

    script_number = 1
    grouped_scripts.each do |language, group_scripts|
      emoji = get_language_emoji(language)
      puts "#{emoji} #{language.upcase} Scripts (#{group_scripts.length} files)"
      puts '─' * 40

      group_scripts.each do |script|
        puts "    [#{script_number.to_s.rjust(2)}] #{script['name']}"
        script_number += 1
      end
      puts ''
    end

    puts '💡 Usage: krun <number> or krun <script_name>'
    puts '🔍 Debug: krun <number> --debug'
    puts '=' * 50
  end

  def group_scripts_by_language(scripts)
    grouped = Hash.new { |h, k| h[k] = [] }

    scripts.each do |script|
      ext = get_file_extension(script['name'])
      lang_info = LANGUAGE_MAP[ext]
      language = lang_info ? lang_info[:name] : 'OTHER'
      grouped[language] << script
    end

    # Sort by predefined order
    order = %w[SHELL PYTHON RUBY PERL JAVASCRIPT LUA R PHP OTHER]
    sorted_grouped = {}

    order.each do |lang|
      sorted_grouped[lang] = grouped[lang] if grouped.key?(lang) && !grouped[lang].empty?
    end

    # Add any remaining languages not in the predefined order
    grouped.each do |lang, scripts|
      sorted_grouped[lang] = scripts unless sorted_grouped.key?(lang)
    end

    sorted_grouped
  end

  def get_language_emoji(language)
    {
      'SHELL' => '🐚',
      'PYTHON' => '🐍',
      'RUBY' => '💎',
      'PERL' => '🐪',
      'JAVASCRIPT' => '🟨',
      'LUA' => '🌙',
      'R' => '📊',
      'PHP' => '🐘',
      'SWIFT' => '🦉',
      'GROOVY' => '☕',
      'SCALA' => '🎯',
      'POWERSHELL' => '💻'
    }.fetch(language, '📄')
  end

  def get_file_extension(filename)
    File.extname(filename).downcase
  end

  def execute_by_number(number, debug = false)
    scripts = get_scripts_list
    unless number.between?(1, scripts.length)
      puts "❌ Error: Invalid script number: #{number}"
      puts "Available scripts: 1-#{scripts.length}"
      exit(1)
    end

    script = scripts[number - 1]
    execute_script(script, debug)
  end

  def execute_by_name(name, debug = false)
    scripts = get_scripts_list
    script = scripts.find { |s| s['name'] == name }

    unless script
      puts "❌ Error: Script '#{name}' not found"
      exit(1)
    end

    execute_script(script, debug)
  end

  def execute_script(script, debug = false)
    script_name = script['name']
    script_url = "#{BASE_URL}/lib/#{script_name}"

    if debug
      show_debug_info(script_name, script_url)
      return
    end

    # Detect interpreter
    interpreter = detect_interpreter(script_name, script_url)
    unless interpreter
      puts "❌ Error: Cannot determine interpreter for #{script_name}"
      puts "Available interpreters: #{available_interpreters.join(', ')}"
      exit(1)
    end

    puts "Executing #{script_name} with #{interpreter}..."

    # Create temporary file and execute
    create_and_execute_temp_script(script_url, interpreter)
  end

  def create_and_execute_temp_script(script_url, interpreter)
    temp_file = create_temp_script(script_url)

    begin
      # Make executable
      File.chmod(0o755, temp_file.path)

      # Execute script
      success = system(interpreter, temp_file.path)
      exit_code = $?.exitstatus

      unless success
        puts "❌ Error: Script execution failed with exit code #{exit_code}"
        exit(exit_code)
      end
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  def show_debug_info(script_name, script_url)
    puts '=== Script Debug Information ==='
    puts "Filename: #{script_name}"
    puts "URL: #{script_url}"
    puts "File extension: #{get_file_extension(script_name)}"

    interpreter = detect_interpreter(script_name, script_url)
    puts "Detected interpreter: #{interpreter || 'unknown'}"

    # Try to detect shebang
    begin
      content = fetch_url(script_url)
      shebang = extract_shebang(content)
      puts "Shebang interpreter: #{shebang || 'none'}"
      puts ''
      puts '=== Script Content ==='
      puts content
    rescue StandardError => e
      puts "Error fetching script: #{e.message}"
    end
  end

  def detect_interpreter(script_name, script_url)
    ext = get_file_extension(script_name)
    lang_info = LANGUAGE_MAP[ext]

    # Try interpreters based on file extension
    if lang_info
      lang_info[:interpreters].each do |interp|
        return interp if command_exists?(interp)
      end
    end

    # Try to detect from shebang as fallback
    detect_interpreter_from_shebang(script_url)
  end

  def detect_interpreter_from_shebang(script_url)
    content = fetch_url(script_url)
    shebang_interp = extract_shebang(content)
    return shebang_interp if shebang_interp && command_exists?(shebang_interp)

    nil
  rescue StandardError
    # Ignore errors when fetching for shebang detection
    nil
  end

  def extract_shebang(content)
    first_line = content.lines.first&.strip
    return nil unless first_line&.start_with?('#!')

    # Extract interpreter from shebang
    shebang = first_line[2..-1].strip

    if shebang.include?(' ')
      # Handle cases like "#!/usr/bin/env bash"
      parts = shebang.split(' ')
      if parts.first.end_with?('/env')
        parts[1]
      else
        File.basename(parts.first)
      end
    else
      File.basename(shebang)
    end
  end

  def command_exists?(command)
    system("which #{command} > /dev/null 2>&1")
  end

  def available_interpreters
    interpreters = []
    LANGUAGE_MAP.each_value do |info|
      info[:interpreters].each do |interp|
        interpreters << interp if command_exists?(interp)
      end
    end
    interpreters.uniq.sort
  end

  def create_temp_script(script_url)
    content = fetch_url(script_url)
    temp_file = Tempfile.new(['krun_script', '.sh'])
    temp_file.write(content)
    temp_file.flush
    temp_file
  end

  def show_status
    puts 'Krun ready!'
    puts 'Supported interpreters:'

    available_extensions = LANGUAGE_MAP.select do |ext, info|
      info[:interpreters].any? { |interp| command_exists?(interp) }
    end

    if available_extensions.empty?
      puts '  No supported interpreters found'
    else
      available_extensions.each do |ext, info|
        available = info[:interpreters].select { |interp| command_exists?(interp) }
        puts "  #{ext}: #{available.join(', ')}"
      end
    end
  end

  def show_languages
    puts 'Supported script languages and extensions:'
    puts ''

    LANGUAGE_MAP.each do |ext, info|
      available = info[:interpreters].select { |interp| command_exists?(interp) }
      status = available.any? ? '✓' : '✗'
      interpreters_str = "(#{info[:interpreters].join(', ')})"

      display_line = if available.any?
                       "  #{status} #{info[:name]}: #{ext} #{interpreters_str}"
                     else
                       "  #{status} #{info[:name]}: #{ext} (Not available)"
                     end

      puts display_line
    end
  end

  def show_version
    puts "Krun Multi-Language Script Runner v#{VERSION}"
    puts 'Copyright (c) 2023 kk'
    puts 'MIT License'
  end

  def show_help
    puts 'Krun Multi-Language Script Runner'
    puts ''
    puts 'Usage:'
    puts '  krun list                    - List all available scripts'
    puts '  krun <number>                - Execute script by number'
    puts '  krun <script_name>           - Execute script by name'
    puts '  krun <number|script> --debug - Show script content and debug info'
    puts '  krun status                  - Show system status and available interpreters'
    puts '  krun languages               - Show supported languages'
    puts '  krun version                 - Show version information'
    puts '  krun help                    - Show this help message'
    puts ''
    puts 'Examples:'
    puts '  krun 1                       - Execute first script'
    puts '  krun hello-world.sh          - Execute hello-world.sh'
    puts '  krun install-python3.py      - Execute Python script'
    puts '  krun config-system.rb        - Execute Ruby script'
    puts '  krun 5 --debug               - Show debug info for script #5'
  end
end

# Main execution
if __FILE__ == $0
  krun = Krun.new
  krun.run(ARGV)
end
