lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'warm_blanket/version'

Gem::Specification.new do |spec|
  spec.name          = 'warm-blanket'
  spec.version       = WarmBlanket::VERSION
  spec.authors       = ['Talkdesk Engineering']
  spec.email         = ['tech@talkdesk.com']

  spec.summary       = 'Ruby gem for warming up web services on boot'
  spec.description   = 'Ruby gem for warming up web services on boot'
  spec.homepage      = 'https://github.com/Talkdesk/warm-blanket'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'rspec', '~> 3.6'
  spec.add_development_dependency 'webmock', '~> 3.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-byebug' unless RUBY_PLATFORM == 'java'
  spec.add_development_dependency 'pry-debugger-jruby' if RUBY_PLATFORM == 'java'

  spec.add_dependency 'faraday', '~> 0.9'
  spec.add_dependency 'dry-configurable', '~> 0.7'
  spec.add_dependency 'logging', '~> 2.1.0'
end
