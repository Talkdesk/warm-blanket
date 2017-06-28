require 'warm_blanket/version'

require 'dry-configurable'
require 'logging'

WarmBlanket.instance_eval do
  extend Dry::Configurable

  # Endpoints to be called for warmup, see README
  setting :endpoints, [], reader: true

  setting :logger, Logging.logger[self], reader: true

  # Local webserver port
  setting :port, ENV['PORT'], reader: true

  # Enable warmup
  setting :enabled, ENV['WARMBLANKET_ENABLED'], reader: true

  # Number of threads to use
  setting :warmup_threads, Integer(ENV['WARMBLANKET_WARMUP_THREADS'] || 2), reader: true

  # Time, in seconds, during which to warm up the service
  setting :warmup_time_seconds, Float(ENV['WARMBLANKET_WARMUP_TIME_SECONDS'] || 150), reader: true
end
