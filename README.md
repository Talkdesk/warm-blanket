# WarmBlanket

WarmBlanket is a Ruby gem for warming up web services on boot. Its main target are JRuby web services, although it is not JRuby-specific in any way.

* [WarmBlanket](#warmblanket)
* [How the magic happens](#how-the-magic-happens)
  * [Why do we need to warm up web services?](#why-do-we-need-to-warm-up-web-services)
  * [What does WarmBlanket do?](#what-does-warmblanket-do)
  * [How does WarmBlanket work?](#how-does-warmblanket-work)
  * [Limitations/caveats](#limitationscaveats)
* [How can I make use of it?](#how-can-i-make-use-of-it)
  * [1. Installation](#1-installation)
  * [2. Configuration settings](#2-configuration-settings)
     * [Configuring endpoints to be called](#configuring-endpoints-to-be-called)
  * [3. Trigger warmup](#3-trigger-warmup)
* [Development](#development)
* [Contributing](#contributing)

<sub><sup>ToC created with [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)</sup></sub>

# How the magic happens

## Why do we need to warm up web services?

When the Java Virtual Machine (JVM) starts, it starts by interpreting Java bytecode. As it starts to detect code that runs often, it just-in-time compiles that code into native machine code, improving performance.

This is a known challenge for most JVMs, and the same applies to JRuby applications, which also run on the JVM.

A widely-documented solution to this problem is to perform a warm-up step when starting a service:

* <https://landing.google.com/sre/book/chapters/load-balancing-datacenter.html#unpredictable-performance-factors-JMs7i7trCj>
* <http://www.brendangregg.com/blog/2016-09-28/java-warmup.html>
* <https://devcenter.heroku.com/articles/warming-up-a-java-process>

## What does WarmBlanket do?

WarmBlanket warms services by performing repeated web requests for a configurable number of seconds. After that time, it closes shop and you'll never hear about it until the next service restart or deploy.

## How does WarmBlanket work?

WarmBlanket spawns a configurable number of background threads that run inside the service process, and then uses an http client to perform local requests to the web server, simulating load.

As it simulates requests, the JVM is warmed up and thus when real requests come in, no performance degradation is observed.

## Limitations/caveats

We strongly recommend that any services using WarmBlanket, if deployed on Heroku, use [Preboot](https://devcenter.heroku.com/articles/preboot). Preboot allows a service instance to be warmed up for 3 minutes before Heroku starts sending live traffic its way, which is preferable to doing it live.

On kubernetes, you can make use of [readiness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) to delay service startup while warm-blanket is working.

# How can I make use of it?

To make use of WarmBlanket, you'll need to follow the next sections, which will guide you through installing, configuring and enabling the gem.

## 1. Installation

To install using Bundler, add the following to your `Gemfile`:

```ruby
gem 'warm-blanket', '~> 1.0'
```

WarmBlanket uses [semantic versioning](http://semver.org/).

## 2. Configuration settings

This gem can be configured via the following environment variables:

* `PORT`: Local webserver port (automatically set on Heroku)
* `WARMBLANKET_ENABLED`: Enable warm blanket (defaults to `false`; `true` or `1` enables)
* `WARMBLANKET_WARMUP_THREADS`: Number of warm up threads to use (defaults to `2`)
* `WARMBLANKET_WARMUP_TIME_SECONDS`: Time, in seconds, during which to warm up the service (defaults to `150`)

### Configuring endpoints to be called

Configure endpoints to be called as follows (on a `config/warm_blanket.rb`:

```ruby
require 'warm-blanket'

WarmBlanket.configure do |config|
  common_headers = {
    'X-Api-Key': ENV.fetch('API_KEYS').split(',').first,
  }

  config.endpoints = [
    {get: '/foo', headers: common_headers},
    {get: '/', headers: common_headers},
  ]
end
```

Other HTTP verbs are supported (and you can pass in a `body` key if needed), but be careful about side effects from such verbs. And if there's no side effect from a `POST` or `PUT`, do consider if it shouldn't be a `GET` instead ;)

```ruby
# Example POST request with body
#
# Notice that you need to both:
# * set the Content-Type manually (if needed)
# * JSON-encode the body  (if needed)

WarmBlanket.configure do |config|
  common_headers = {
    'X-Api-Key': ENV.fetch('API_KEY').split(',').first,
    'Content-Type': 'application/json',
  }

  post_body = MultiJson.dump(
    account_id: 'dummy_account',
    user_id: 'dummy_user_id',
  )

  config.endpoints = [
    {post: '/some_endoint', headers: common_headers, body: post_body},
  ]
end
```

## 3. Trigger warmup

Add the following to the end of your `config.ru` file:

```ruby
WarmBlanket.trigger_warmup
```

# Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

# Contributors

Open-sourced with :heart: by Talkdesk!

Maintained by [Ivo Anjo](https://github.com/ivoanjo/) and the [Talkdesk Engineering](http://github.com/Talkdesk/) team.

# Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/Talkdesk/warm-blanket>.
