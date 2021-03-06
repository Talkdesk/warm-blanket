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

require 'faraday'

module WarmBlanket
  # Issues one request per call to the configured endpoint
  class Requester

    InvalidHTTPVerb = Class.new(StandardError)

    private

    SUPPORTED_VERBS = [:get, :post, :put].freeze
    private_constant :SUPPORTED_VERBS

    attr_reader :base_url
    attr_reader :default_headers
    attr_reader :endpoints
    attr_reader :logger
    attr_reader :connection_factory

    attr_accessor :next_endpoint_position

    public

    def initialize(base_url:, default_headers:, endpoints:, logger: WarmBlanket.config.logger, connection_factory: Faraday)
      @base_url = base_url
      @default_headers = default_headers
      @endpoints = endpoints
      @logger = logger
      @connection_factory = connection_factory
      @next_endpoint_position = 0
    end

    def call
      connection = connection_factory.new(url: base_url)

      endpoint = next_endpoint

      http_verb = extract_verb(endpoint)

      logger.debug "Requesting #{endpoint.fetch(http_verb)}"

      response = connection.public_send(http_verb) do |request|
        apply_headers(request, default_headers)
        apply_headers(request, endpoint[:headers])
        request.url(endpoint.fetch(http_verb))
        request.body = endpoint[:body] if endpoint[:body]
      end

      if response.status == 200
        logger.debug "Request successful"
      else
        logger.warn "Request to #{endpoint.fetch(http_verb)} failed with code #{response.status}"
      end

      nil
    end

    private

    def apply_headers(request, headers)
      headers&.each do |header, value|
        request.headers[header.to_s] = value
      end
    end

    def next_endpoint
      next_endpoint = endpoints[next_endpoint_position]
      self.next_endpoint_position = (next_endpoint_position + 1) % endpoints.size
      next_endpoint
    end

    def extract_verb(endpoint)
      SUPPORTED_VERBS.each do |verb|
        return verb if endpoint.key?(verb)
      end

      raise InvalidHTTPVerb, "Unsupported or missing HTTP verb for request: #{endpoint.inspect}"
    end
  end
end
