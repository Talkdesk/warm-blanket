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
