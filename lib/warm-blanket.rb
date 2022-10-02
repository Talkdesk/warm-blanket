# WarmBlanket: Ruby gem for warming up web services on boot
# Copyright (C) 2017 Talkdesk, Inc. <tech@talkdesk.com>
#
# This file is part of WarmBlanket.
#
# WarmBlanket is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# WarmBlanket is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with WarmBlanket.  If not, see <http://www.gnu.org/licenses/>.

require 'warm_blanket/version'
require 'warm_blanket/orchestrator'

require 'dry-configurable'
require 'logging'

module WarmBlanket
  extend Dry::Configurable

  # Compatibility with Ruby 2.3 / JRuby 9.1: Modern versions of dry-configurable emit deprecation warnings for the way
  # we're passing in defaults, but older versions of the gem don't work on the older Ruby/JRuby versions.
  # See https://github.com/dry-rb/dry-configurable/blob/main/CHANGELOG.md#0130-2021-09-12 .
  # This can be dropped when we drop support for Ruby 2.3/JRuby 9.1
  if Dry::Configurable.respond_to?(:warn_on_setting_positional_default)
    Dry::Configurable.warn_on_setting_positional_default(false)
  end

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

  def self.trigger_warmup(logger: WarmBlanket.config.logger, orchestrator_factory: Orchestrator)
    unless [true, 'true', '1'].include?(WarmBlanket.config.enabled)
      logger.info "WarmBlanket not enabled, ignoring trigger_warmup"
      return false
    end

    orchestrator_factory.new.call
  end
end
