# WarmBlanket

**WarmBlanket is still a prototype. YMMV**

WarmBlanket is a Ruby gem for warming up web services on boot. Its main target are JRuby web services, although it is not JRuby-specific in any way.

# Why do we need to warm up web services?

When the Java Virtual Machine (JVM) starts, it starts by interpreting Java bytecode. As it starts to detect code that runs often, it just-in-time compiles that code into native machine code, improving performance.

This is a known challenge for most JVMs, and the same applies to JRuby applications, which also run on the JVM.

A widely-documented solution to this problem is to perform a warm-up step when starting a service:

* <https://landing.google.com/sre/book/chapters/load-balancing-datacenter.html#unpredictable-performance-factors-JMs7i7trCj>
* <http://www.brendangregg.com/blog/2016-09-28/java-warmup.html>
* <https://devcenter.heroku.com/articles/warming-up-a-java-process>

# What does WarmBlanket do?

WarmBlanket warms services by performing repeated web requests for a configurable number of seconds.

# How does WarmBlanket work?

WarmBlanket spawns a configurable number of background threads that run inside the service process, and then uses an http client to perform local requests to the web server, simulating load.

As it simulates requests, the JVM is warmed up and thus when real requests come in, no performance degradation is observed.

# Limitations/caveats

We strongly recommend that any services using WarmBlanket, if deployed on Heroku, use [Preboot](https://devcenter.heroku.com/articles/preboot). Preboot allows a service instance to be warmed up for 3 minutes before Heroku starts sending live traffic its way, which is preferable to doing it live.

# Installation

To install using Bundler, add the following to your `Gemfile`:

```ruby
gem 'warm-blanket', '~> 0.1',
  git: 'https://github.com/Talkdesk/warm-blanket.git'
```

To install a particular version, add the `tag` option:

```ruby
gem 'warm-blanket', '~> 0.1',
  git: 'https://github.com/Talkdesk/warm-blanket.git',
  tag: 'v0.1.0'
```
