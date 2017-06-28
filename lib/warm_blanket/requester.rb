require 'faraday'

module WarmBlanket
  # Issues one request per call to the configured endpoint
  class Requester

    private

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

      logger.debug "Requesting #{endpoint.fetch(:get)}"

      response = connection.get do |request|
        apply_headers(request, default_headers)
        apply_headers(request, endpoint[:headers])
        request.url(endpoint.fetch(:get))
      end

      if response.status == 200
        logger.debug "Request successful"
      else
        logger.warn "Request to #{endpoint.fetch(:get)} failed with code #{response.status}"
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
  end
end
