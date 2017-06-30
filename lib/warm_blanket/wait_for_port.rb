require 'socket'
require 'time'

module WarmBlanket
  # Waits for given port to be available
  class WaitForPort

    InvalidPort = Class.new(StandardError)

    private

    attr_reader :hostname
    attr_reader :port
    attr_reader :logger
    attr_reader :time_deadline

    public

    def initialize(hostname: 'localhost', port:, time_deadline: (Time.now + 90), logger: WarmBlanket.config.logger)
      port = Integer(port) rescue nil
      raise InvalidPort, "Invalid port (#{port.inspect})" unless (1...2**16).include?(port)

      @hostname = hostname
      @port = port
      @logger = logger
      @time_deadline = time_deadline
    end

    def call
      logger.debug "Waiting for #{hostname}:#{port} to be available"

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

        return false if Time.now >= time_deadline
        sleep 1
      end
    end
  end
end
