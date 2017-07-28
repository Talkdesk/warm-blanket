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

# frozen_string_literal: true

require 'warm_blanket/requester'
require 'warm_blanket/wait_for_port'

module WarmBlanket
  # Orchestrates threads to wait for the port to open and to perform the warmup requests
  class Orchestrator

    DEFAULT_HEADERS = {
      'X-Forwarded-Proto': 'https',
      'X-Request-Id': 'WarmBlanket',
      'X-Client-Id': 'WarmBlanket',
    }.freeze

    private

    attr_reader :requester_factory
    attr_reader :wait_for_port_factory
    attr_reader :logger
    attr_reader :endpoints
    attr_reader :hostname
    attr_reader :port
    attr_reader :warmup_threads
    attr_reader :warmup_deadline

    public

    def initialize(
      requester_factory: Requester,
      wait_for_port_factory: WaitForPort,
      logger: WarmBlanket.config.logger,
      endpoints: WarmBlanket.config.endpoints,
      hostname: 'localhost',
      port: WarmBlanket.config.port,
      warmup_threads: WarmBlanket.config.warmup_threads,
      warmup_time_seconds: WarmBlanket.config.warmup_time_seconds
    )
      raise "Warmup threads cannot be less than 1 (got #{warmup_threads})" if warmup_threads < 1

      @requester_factory = requester_factory
      @wait_for_port_factory = wait_for_port_factory
      @logger = logger
      @endpoints = endpoints
      @hostname = hostname
      @port = port
      @warmup_threads = warmup_threads
      @warmup_deadline = Time.now + warmup_time_seconds
    end

    def call
      safely_spawn_thread do
        logger.debug 'Started orchestrator thread'
        orchestrate
      end
    end

    private

    def safely_spawn_thread(&block)
      Thread.new do
        begin
          block.call
        rescue => e
          logger.error "Caught error that caused background thread to die #{e.class}: #{e.message}"
          logger.debug "#{e.backtrace.join("\n")}"
        end
      end
    end

    def orchestrate
      success = wait_for_port_to_open

      spawn_warmup_threads if success
    end

    def wait_for_port_to_open
      wait_for_port_factory.new(port: port, time_deadline: warmup_deadline).call
    end

    def spawn_warmup_threads
      # Create remaining threads
      (warmup_threads - 1).times do
        safely_spawn_thread do
          perform_warmup_requests
        end
      end

      # Reuse current thread
      perform_warmup_requests
    end

    def perform_warmup_requests
      success = false

      if Time.now >= warmup_deadline
        logger.warn "Warmup deadline already passed, will skip warmup"
        return
      end

      logger.debug "Starting warmup requests (remaining deadline: #{[warmup_deadline - Time.now, 0].max})"

      requester = requester_factory.new(
        base_url: "http://#{hostname}:#{port}",
        default_headers: DEFAULT_HEADERS,
        endpoints: endpoints,
      )

      while Time.now < warmup_deadline
        requester.call
      end

      success = true
    ensure
      logger.info "Finished warmup work #{success ? 'successfully' : 'with error'}"
    end
  end
end
