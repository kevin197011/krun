#!/usr/bin/env perl
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use File::Temp qw(tempfile);
use File::Basename qw(basename);
use Getopt::Long;

package Krun;

our $VERSION = "2.0 (Perl)";
our $BASE_URL = "https://raw.githubusercontent.com/kevin197011/krun/main";
our $LIST_URL = "$BASE_URL/resources/krun.json";
our $USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36";

# Supported interpreters
my %INTERPRETERS = (
    '.sh'         => ['bash'],
    '.bash'       => ['bash'],
    '.zsh'        => ['zsh'],
    '.py'         => ['python3', 'python'],
    '.python'     => ['python3', 'python'],
    '.rb'         => ['ruby'],
    '.ruby'       => ['ruby'],
    '.pl'         => ['perl'],
    '.perl'       => ['perl'],
    '.js'         => ['node'],
    '.javascript' => ['node'],
    '.lua'        => ['lua'],
    '.r'          => ['Rscript'],
    '.R'          => ['Rscript'],
    '.php'        => ['php'],
    '.swift'      => ['swift'],
    '.groovy'     => ['groovy'],
    '.scala'      => ['scala'],
    '.ps1'        => ['powershell', 'pwsh'],
    '.fish'       => ['fish']
);

sub new {
    my $class = shift;
    my $self = {
        ua => LWP::UserAgent->new(agent => $USER_AGENT),
        scripts => undef
    };
    bless $self, $class;
    return $self;
}

sub run {
    my ($self, @args) = @_;

    if (@args < 2) {
        $self->help();
        return;
    }

    my $command = $args[1];

    if ($command eq 'list') {
        $self->list();
    } elsif ($command eq 'help') {
        $self->help();
    } elsif ($command eq 'status') {
        $self->status();
    } elsif ($command eq 'version') {
        $self->version();
    } elsif ($command eq 'languages') {
        $self->languages();
    } elsif ($command =~ /^\d+$/) {
        my $opt = int($command);
        my $debug_mode = (@args >= 3 && $args[2] eq '--debug');
        if ($debug_mode) {
            $self->debug($opt);
        } else {
            $self->execute_script($opt);
        }
    } elsif ($self->is_script_name($command)) {
        my $debug_mode = (@args >= 3 && $args[2] eq '--debug');
        if ($debug_mode) {
            $self->debug($command);
        } else {
            $self->execute_script($command);
        }
    } else {
        print "Error: Unknown command '$command'\n";
        $self->help();
        exit 1;
    }
}

sub http_get {
    my ($self, $url) = @_;
    my $response = $self->{ua}->get($url);

    if ($response->is_success) {
        return $response->decoded_content;
    } else {
        die "HTTP request failed: " . $response->status_line;
    }
}

sub command_exists {
    my ($self, $command) = @_;
    my $result = system("which $command > /dev/null 2>&1");
    return $result == 0;
}

sub get_file_extension {
    my ($self, $filename) = @_;
    if ($filename =~ /\.([^.]+)$/) {
        return lc(".$1");
    }
    return '';
}

sub detect_interpreter_from_shebang {
    my ($self, $content) = @_;
    my @lines = split /\n/, $content;
    return undef unless @lines && $lines[0] =~ /^#!/;

    my $shebang = $lines[0];
    $shebang =~ s/^#!//;

    return 'python3' if $shebang =~ /python3/;
    return 'python'  if $shebang =~ /python/;
    return 'ruby'    if $shebang =~ /ruby/;
    return 'perl'    if $shebang =~ /perl/;
    return 'node'    if $shebang =~ /node/;
    return 'bash'    if $shebang =~ /bash/;
    return 'zsh'     if $shebang =~ /zsh/;
    return 'fish'    if $shebang =~ /fish/;
    return 'lua'     if $shebang =~ /lua/;
    return 'php'     if $shebang =~ /php/;

    return undef;
}

sub get_interpreter {
    my ($self, $filename, $content) = @_;
    my $ext = $self->get_file_extension($filename);

    # Try interpreters from extension
    if (exists $INTERPRETERS{$ext}) {
        for my $interpreter (@{$INTERPRETERS{$ext}}) {
            return $interpreter if $self->command_exists($interpreter);
        }
    }

    # Try shebang detection
    if (defined $content) {
        my $shebang_interpreter = $self->detect_interpreter_from_shebang($content);
        if (defined $shebang_interpreter && $self->command_exists($shebang_interpreter)) {
            return $shebang_interpreter;
        }
    }

    # Default fallback
    return 'bash' if $ext eq '' || $ext eq '.sh' || $ext eq '.bash';

    return undef;
}

sub is_script_name {
    my ($self, $name) = @_;
    return $name =~ /\.(sh|py|rb|pl|js|lua|r|php|swift|groovy|scala|ps1|fish|bash|zsh|python|ruby|perl|javascript)$/;
}

sub get_script_list {
    my ($self) = @_;
    unless (defined $self->{scripts}) {
        my $content = $self->http_get($LIST_URL);
        $self->{scripts} = decode_json($content);
    }
    return @{$self->{scripts}};
}

sub group_scripts_by_language {
    my ($self, @scripts) = @_;
    my %groups = (
        shell      => [],
        python     => [],
        ruby       => [],
        perl       => [],
        javascript => [],
        other      => []
    );

    for my $script (@scripts) {
        my $ext = $self->get_file_extension($script);
        if ($ext =~ /^\.(?:sh|bash|zsh|fish)$/) {
            push @{$groups{shell}}, $script;
        } elsif ($ext =~ /^\.(?:py|python)$/) {
            push @{$groups{python}}, $script;
        } elsif ($ext =~ /^\.(?:rb|ruby)$/) {
            push @{$groups{ruby}}, $script;
        } elsif ($ext =~ /^\.(?:pl|perl)$/) {
            push @{$groups{perl}}, $script;
        } elsif ($ext =~ /^\.(?:js|javascript)$/) {
            push @{$groups{javascript}}, $script;
        } else {
            push @{$groups{other}}, $script;
        }
    }

    return %groups;
}

sub list {
    my ($self) = @_;
    print "🚀 Krun Multi-Language Script Collection\n";
    print "=" x 50 . "\n";

    my @scripts = $self->get_script_list();
    my $total_scripts = scalar @scripts;
    my %grouped_scripts = $self->group_scripts_by_language(@scripts);
    my $num = 1;

    # Language icons mapping
    my %lang_icons = (
        'shell'      => '🐚',
        'python'     => '🐍',
        'ruby'       => '💎',
        'perl'       => '🐪',
        'javascript' => '🟨',
        'other'      => '📄'
    );

    # Display summary
    print "\n📊 Total Scripts: $total_scripts\n";

    my $active_groups = 0;
    for my $lang (keys %grouped_scripts) {
        $active_groups++ if @{$grouped_scripts{$lang}};
    }
    print "📁 Categories: $active_groups\n\n";

    for my $lang (qw(shell python ruby perl javascript other)) {
        next unless @{$grouped_scripts{$lang}};

        my $icon = $lang_icons{$lang} || '📄';
        my $count = scalar @{$grouped_scripts{$lang}};
        print "$icon " . uc($lang) . " Scripts ($count files)\n";
        print "─" x 40 . "\n";

        for my $script (@{$grouped_scripts{$lang}}) {
            printf "    [%2d] %s\n", $num, $script;
            $num++;
        }
        print "\n";
    }

    print "💡 Usage: krun <number> or krun <script_name>\n";
    print "🔍 Debug: krun <number> --debug\n";
    print "=" x 50 . "\n";
}

sub status {
    my ($self) = @_;
    print "Krun ready!\n";
    print "Supported interpreters:\n";

    for my $ext (sort keys %INTERPRETERS) {
        my @available;
        for my $interpreter (@{$INTERPRETERS{$ext}}) {
            push @available, $interpreter if $self->command_exists($interpreter);
        }
        next unless @available;

        print "  $ext: " . join(', ', @available) . "\n";
    }
}

sub version {
    my ($self) = @_;
    print "Krun Multi-Language Script Runner v$VERSION\n";
    print "Copyright (c) 2023 kk\n";
    print "MIT License\n";
}

sub languages {
    my ($self) = @_;
    print "Supported script languages and extensions:\n\n";

    my %lang_map = (
        'Shell/Bash'            => [qw(.sh .bash .zsh .fish)],
        'Python'                => [qw(.py .python)],
        'Ruby'                  => [qw(.rb .ruby)],
        'Perl'                  => [qw(.pl .perl)],
        'JavaScript (Node.js)'  => [qw(.js .javascript)],
        'Lua'                   => [qw(.lua)],
        'R'                     => [qw(.r .R)],
        'PHP'                   => [qw(.php)],
        'Swift'                 => [qw(.swift)],
        'Groovy'                => [qw(.groovy)],
        'Scala'                 => [qw(.scala)],
        'PowerShell'            => [qw(.ps1)]
    );

    for my $lang (sort keys %lang_map) {
        my @exts = @{$lang_map{$lang}};
        my @available_interpreters;

        for my $ext (@exts) {
            next unless exists $INTERPRETERS{$ext};

            for my $interpreter (@{$INTERPRETERS{$ext}}) {
                if ($self->command_exists($interpreter)) {
                    push @available_interpreters, $interpreter;
                    last;
                }
            }
        }

        my $status = @available_interpreters ? '✓' : '✗';
        my $interpreters_str = @available_interpreters ? join(', ', @available_interpreters) : 'Not available';

        print "  $status $lang: " . join(' ', @exts) . " ($interpreters_str)\n";
    }
}

sub help {
    my ($self) = @_;
    print <<'EOF';
Krun Multi-Language Script Runner

Usage:
  krun list                    - List all available scripts
  krun <number>                - Execute script by number
  krun <script_name>           - Execute script by name
  krun <number|script> --debug - Show script content and debug info
  krun status                  - Show system status and available interpreters
  krun languages               - Show supported languages
  krun version                 - Show version information
  krun help                    - Show this help message

Examples:
  krun 1                       - Execute first script
  krun hello-world.sh          - Execute hello-world.sh
  krun install-python3.py      - Execute Python script
  krun config-system.rb        - Execute Ruby script
  krun 5 --debug               - Show debug info for script #5
EOF
}

sub get_script_url {
    my ($self, $opt) = @_;
    my $script_name;

    if ($opt =~ /^\d+$/) {
        my @scripts = $self->get_script_list();
        my $index = $opt - 1;
        if ($index >= 0 && $index < @scripts) {
            $script_name = $scripts[$index];
        } else {
            die "Error: Invalid script number: $opt\n";
        }
    } else {
        $script_name = $opt;
    }

    return "$BASE_URL/lib/$script_name";
}

sub debug {
    my ($self, $opt) = @_;
    my $url = $self->get_script_url($opt);
    my $filename = basename($url);
    my $content = $self->http_get($url);

    print "=== Script Debug Information ===\n";
    print "Filename: $filename\n";
    print "URL: $url\n";
    print "File extension: " . $self->get_file_extension($filename) . "\n";

    my $interpreter = $self->get_interpreter($filename, $content);
    print "Detected interpreter: " . (defined $interpreter ? $interpreter : 'Unknown') . "\n";

    my $shebang_interpreter = $self->detect_interpreter_from_shebang($content);
    print "Shebang interpreter: $shebang_interpreter\n" if defined $shebang_interpreter;

    print "\n=== Script Content ===\n";
    print $content;
}

sub execute_script {
    my ($self, $opt) = @_;
    my $url = $self->get_script_url($opt);
    my $filename = basename($url);

    # Download script content
    my $content = $self->http_get($url);

    # Determine interpreter
    my $interpreter = $self->get_interpreter($filename, $content);

    unless (defined $interpreter) {
        die "Error: Cannot determine interpreter for $filename\n";
    }

    # Create temporary file
    my $ext = $self->get_file_extension($filename);
    my ($fh, $temp_file) = tempfile('krun-XXXX', SUFFIX => $ext, UNLINK => 1);
    print $fh $content;
    close $fh;
    chmod 0755, $temp_file;

    # Execute with appropriate interpreter
    print "Executing $filename with $interpreter...\n";
    exec($interpreter, $temp_file) or die "Error executing script: $!\n";
}

package main;

# Main execution
if (!caller) {
    my $krun = Krun->new();
    $krun->run(@ARGV);
}