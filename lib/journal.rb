require 'journal/version'
require 'date'
require 'yaml'

module HawkPrime

  # Logger Class
  #
  # Logging Example:
  #
  #   log = HawkPrime::Logger[self.class]
  #   log.debug('before change')
  #
  #
  # Output logging with one or multiple appenders
  #
  #   HawkPrime::Logger.add_appender HawkPrime::Logger::ConsoleAppender.new 'con', :info
  #   HawkPrime::Logger.add_appender HawkPrime::Logger::FileAppender.new 'file', 'a.log', :debug
  #
  #
  # Use custom formatter for appender
  #
  #   con = HawkPrime::Logger::ConsoleAppender.new
  #   con.formatter = MyFormatter.new
  #
  # Custom formatter must define the following method:
  #
  #   def format(logger_name, level, message)
  #
  # Control output
  #
  #   # Set level default level (root level)
  #   Logger.level = :warn
  #
  #   # Only output info and higher for specifc logger
  #   log.level = :info
  #
  #   # Only output warn or higher for specifc appender
  #   con.level = :warn
  #
  # Message level filtering follows this path:
  #
  #   root level => logger level => appender level
  #
  # That is if root is set to info, nothing lower than info
  # is sent down to the logger or appenders. Like wise if a
  # specific logger is set to warn, nothing lower will be
  # sent to the appenders.
  #
  # Read config file
  #
  #   HawkPrime::Logger.config 'config.yml'
  #
  class Logger
    LEVELS = [:trace, :debug, :info, :warn, :error] # rubocop:disable MutableConstant

    @@loggers = {}
    @@appenders = {}
    @@root_level = :debug

    # Set the Logger root level
    attr_accessor :level

    # Creates or retreives existing logger.
    #
    # @param name logger name
    # @param level level or nil to use root logger level
    #
    # @return [Logger] logger
    #
    def self.logger(name, level = nil)
      return @@loggers[name.to_s] if @@loggers.key? name.to_s
      @@loggers[name.to_s] = Logger.new(name.to_s, level)
    end

    def self.[](name)
      logger(name)
    end

    # Set the root logger level
    def self.level=(level)
      @@root_level = level
    end

    # Get the root logger level
    def self.level
      @@root_level
    end

    # Add appender
    def self.add_appender(appender)
      @@appenders[appender.name] = appender
    end

    # Retreive appender
    def self.appender(name)
      @@appenders[name]
    end

    # Configure loggers/appenders based on config file
    #
    # Sample config file:
    #
    #   appenders:
    #     # For console type only name is required
    #     -
    #       name: console
    #       type: console
    #       formatter: TestFormatter
    #       level: info
    #       fd: STDERR
    #
    #     # For file type only name and file are required
    #     # relative paths are relative to config file dir
    #     -
    #       name: file
    #       type: file
    #       file: app.log
    #       level: debug
    #       truncate: true
    #       formatter: TestFormatter
    #
    #   loggers:
    #     root: trace
    #     App.LoggingController: debug
    #     'test_passing(LoggerTest)': trace
    #
    def self.config(file)
      logger_config = YAML.load(File.open(file).read)
      create_loggers logger_config['loggers'] if logger_config.key? 'loggers'
      create_appenders File.dirname(file), logger_config['appenders'] if logger_config.key? 'appenders'
      log = self[:Logger]
      log.debug "Loaded config file \"#{file}\""
    end

    # Search for logger configuration and load it.
    #
    # will search the following and load the first one found:
    #
    #   config/logger.ENV['RACK_ENV'].yml
    #   config/logger.yml
    #   ./logger.ENV['RACK_ENV'].yml
    #   ./logger.yml
    #
    def self.auto_config
      paths = %w(.)
      paths.insert 0, 'config' if File.directory? 'config'

      files = %w(logger.yml)
      files.insert 0, "logger.#{ENV['RACK_ENV']}.yml" if ENV.key? 'RACK_ENV'

      paths.each do |path|
        files.each do |file|
          config_file = File.join(path, file)
          return config config_file if File.file? config_file
        end
      end
    end

    def trace(message)
      log :trace, message
    end

    def debug(message)
      log :debug, message
    end

    def info(message)
      log :info, message
    end

    def warn(message)
      log :warn, message
    end

    def error(message)
      log :error, message
    end

    def log(level, message)
      return unless Logger.loggable level, @level
      @@appenders.each_value do |appender|
        appender.log(@name, level, message)
      end
    end

    def self.create_loggers(loggers)
      return if loggers.nil?
      loggers.each do |name, level_str|
        level = level_str.downcase.to_sym
        if name.casecmp('root').zero?
          Logger.level = level
        else
          logger name, level
        end
      end
    end

    def self.create_appenders(config_path, appenders)
      return if appenders.nil?
      appenders.each do |appender_config|
        if appender_config['type'] == 'console'
          Logger.add_appender ConsoleAppender.build appender_config

        elsif appender_config['type'] == 'file'
          appender_config['path'] = config_path
          Logger.add_appender FileAppender.build appender_config
        end
      end
    end

    # ANSI formatter
    class AnsiFormatter
      COLORS = {
        trace: "\e[35m",
        debug: "\e[34m",
        info:  "\e[32m",
        warn:  "\e[33m",
        error: "\e[31m"
      }.freeze

      def format(logger_name, level, message)
        sprintf( # rubocop:disable FormatString
          "%s%s %-5s %s: %s\e[0m",
          COLORS.key?(level) ? COLORS[level] : '',
          DateTime.now.strftime('%F %T.%L'),
          level.to_s.upcase,
          logger_name,
          message
        )
      end
    end

    # Simple formatter
    class SimpleFormatter
      def format(logger_name, level, message)
        sprintf( # rubocop:disable FormatString
          '%s %-5s %s: %s',
          DateTime.now.strftime('%F %T.%L'),
          level.to_s.upcase,
          logger_name,
          message
        )
      end
    end

    # Abstract Appender
    class AbstractAppender
      attr_accessor :level, :formatter, :fd
      attr_reader :name

      def initialize(name, level, formatter)
        @name = name
        @level = level
        @formatter = formatter.nil? ? SimpleFormatter.new : formatter
      end

      def log(logger, msg_level, message)
        return unless Logger.loggable msg_level, @level
        # If appender level set, check it otherwise use root level
        @fd.puts @formatter.format(logger, msg_level, message)
      end
    end

    # File Appender
    class FileAppender < AbstractAppender
      def self.build(ops)
        FileAppender.new(
          ops['name'],
          File.expand_path(ops['file'], ops['path']),
          ops.key?('level') ? ops['level'].downcase.to_sym : nil,
          ops.key?('truncate') ? ops['truncate'] : false,
          ops.key?('formatter') ? Object.const_get("HawkPrime::Logger::#{ops['formatter']}").new : nil
        )
      end

      def initialize(name, file, level = nil, truncate = false, formatter = nil)
        super(name, level, formatter)
        @fd = File.open(file, truncate ? 'w' : 'a')
      end
    end

    # Console Appender
    class ConsoleAppender < AbstractAppender
      def self.build(ops)
        ConsoleAppender.new(
          ops['name'],
          ops.key?('level') ? ops['level'].downcase.to_sym : nil,
          ops.key?('formatter') ? Object.const_get("HawkPrime::Logger::#{ops['formatter']}").new : nil,
          file_descriptor(ops)
        )
      end

      def initialize(name, level = nil, formatter = nil, fd = nil)
        super(name, level, formatter)
        @fd = fd.nil? ? STDOUT : fd
      end

      def self.file_descriptor(fd_config)
        return nil unless fd_config.key? 'fd'
        fd_config['fd'].casecmp('STDERR').zero? ? STDERR : STDOUT
      end
    end

    def self.loggable(msg_level, level)
      return LEVELS.index(msg_level) >= LEVELS.index(level) unless level.nil?
      return true if LEVELS.index(msg_level).nil? || LEVELS.index(@@root_level).nil?
      LEVELS.index(@@root_level) <= LEVELS.index(msg_level)
    end

    private

    def initialize(name, level)
      @name = name
      @level = level
    end
  end
end
