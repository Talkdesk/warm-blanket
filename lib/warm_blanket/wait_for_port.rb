require 'socket'

module WarmBlanket
  # Waits for given port to be available
  class WaitForPort

    InvalidPort = Class.new(StandardError)

    private

    attr_reader :hostname
    attr_reader :port
    attr_reader :logger
    attr_reader :tries_limit

    public

    def initialize(hostname: 'localhost', port:, tries_limit: 90, logger: WarmBlanket.config.logger)
      port = Integer(port)
      raise "Invalid port (#{port.inspect})" unless (1...2**16).include?(port)

      @hostname = hostname
      @port = port
      @logger = logger
      @tries_limit = tries_limit
    end

    def call
      logger.debug "Waiting for #{hostname}:#{port} to be available"

      tries = 0

      while true
        socket = nil
        begin
          socket = TCPSocket.new(hostname, port)
          logger.debug "Service at #{hostname}:#{port} is up"
          return true
        rescue StandardError => e
          logger.debug "Exception while waiting for port to be available #{e.class}: #{e.message}"
        ensure
          socket&.close
        end

        tries += 1
        return false if tries >= tries_limit
        sleep 1
      end
    end
  end
end
