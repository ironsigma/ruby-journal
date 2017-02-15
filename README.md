# Logger

Yet another logger class.

## Usage

Logger Class

Logging Example:

```ruby
  log = HawkPrime::Logger[self.class]
  log.debug('before change')
```

Output logging with one or multiple appenders

```ruby
  HawkPrime::Logger.add_appender HawkPrime::Logger::ConsoleAppender.new 'con', :info
  HawkPrime::Logger.add_appender HawkPrime::Logger::FileAppender.new 'file', 'a.log', :debug
```

Use custom formatter for appender

```ruby
  con = HawkPrime::Logger::ConsoleAppender.new
  con.formatter = MyFormatter.new
```

Custom formatter must define the following method:

```ruby
  def format(logger_name, level, message)
```

Control output

```ruby
  # Set level default level (root level)
  Logger.level = :warn

  # Only output info and higher for specifc logger
  log.level = :info

  # Only output warn or higher for specifc appender
  con.level = :warn
```

Message level filtering follows this path:

```ruby
  root level => logger level => appender level
```

That is if root is set to info, nothing lower than info
is sent down to the logger or appenders. Like wise if a
specific logger is set to warn, nothing lower will be
sent to the appenders.

## Configuration

Configure loggers/appenders based on config file

```ruby
  HawkPrime::Logger.config 'config.yml'
```

Sample config file:

```yaml
  appenders:
    # For console type only name is required
    -
      name: console
      type: console
      formatter: TestFormatter
      level: info
      fd: STDERR

    # For file type only name and file are required
    # relative paths are relative to config file dir
    -
      name: file
      type: file
      file: app.log
      level: debug
      truncate: true
      formatter: TestFormatter

  loggers:
    root: trace
    App.LoggingController: debug
    'test_passing(LoggerTest)': trace
```


To automatically search for a config file use:

```ruby
  HawkPrime::Logger.auto_config
```

This will search the following and load the first one found:

```ruby
  "config/logger.#{ENV['RACK_ENV']}.yml"
  "config/logger.yml"
  "./logger.#{ENV['RACK_ENV']}.yml"
  "./logger.yml"
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'logger', :git => 'https://github.com/hawkprime/ruby-logger.git'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install logger
