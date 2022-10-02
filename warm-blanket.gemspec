lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'warm_blanket/version'

Gem::Specification.new do |spec|
  spec.name          = 'warm-blanket'
  spec.version       = WarmBlanket::VERSION
  spec.authors       = ['Talkdesk Engineering']
  spec.email         = ['tech@talkdesk.com']
  spec.license       = 'LGPL-3.0+'

  spec.summary       = 'Ruby gem for warming up web services on boot'
  spec.description   = 'Ruby gem for warming up web services on boot'
  spec.homepage      = 'https://github.com/Talkdesk/warm-blanket'

  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0")
      .reject { |f| f.match(%r{\A(?:test|spec|features|[.]github|examples)/}) }
      .reject { |f|
        ["gems.rb", ".ruby-version", ".gitignore", ".rspec",
          "Rakefile", "bin/pry", "bin/rspec", "bin/console"].include?(f)
      }
  end
  spec.require_paths = ['lib']

  spec.required_ruby_version = ">= 2.3.0"

  spec.add_development_dependency 'bundler', '~> 2.3'
  spec.add_development_dependency 'rspec', '~> 3.11'
  spec.add_development_dependency 'webmock', '~> 3.18'
  spec.add_development_dependency 'timecop', '~> 0.9'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-byebug' unless RUBY_PLATFORM == 'java'
  spec.add_development_dependency 'pry-debugger-jruby' if RUBY_PLATFORM == 'java'
  spec.add_development_dependency 'webrick', '~> 1.7.0'

  spec.add_dependency 'faraday', '~> 1.10'
  spec.add_dependency 'dry-configurable', '~> 0.7'
  spec.add_dependency 'logging', '~> 2.1'
end
