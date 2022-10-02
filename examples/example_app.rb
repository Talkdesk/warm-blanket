require "webrick"
require "pry"
require "warm-blanket"
require "logging"

puts "Using #{RUBY_DESCRIPTION}"

PORT = ENV["PORT"] || 8080

Logging.logger.root.add_appenders(Logging.appenders.stdout(
  layout: Logging.layouts.pattern(pattern: '[%d] %-5l %c: %m\n', date_pattern: '%Y-%m-%d %H:%M:%S')
))

WarmBlanket.configure do |config|
  common_headers = {
    "X-Api-Key": "test-api-key",
  }

  config.port = PORT
  config.endpoints = [
    {get: "/foo", headers: common_headers},
    {get: "/", headers: common_headers},
  ]
  config.enabled = true
  config.warmup_time_seconds = 3
end

WarmBlanket.trigger_warmup

server = WEBrick::HTTPServer.new(Port: PORT)

server.mount_proc("/") do |request, response|
  response.body = "/ endpoint"
end

server.mount_proc("/foo") do |request, response|
  response.body = "/foo endpoint"
end

trap("INT") do
  server.shutdown
end

server.start
