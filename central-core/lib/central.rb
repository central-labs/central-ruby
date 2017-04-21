require 'central/version'
require 'connection_pool'
require 'logger'
require 'concurrent-edge'
require 'securerandom'
require 'json'

module Central
  #
  # Class that host redis pubsub client logics and setter-getter value.
  #
  # By default, monitor thread will monitor message in "mothership:*" namespace.
  #
  # To resolve duplicated message or event we identify each `Central::Client` instance
  # with *hopefully* unique uuid using ruby `SecureRandom.uuid`. So, that `Central::Client`
  # instance won't have receive its own published changes and create `stupid chain reaction`.
  #
  # Any method that ends with `!` will actually publish the event to redis.
  #
  # @author Yuri Setiantoko <yuri@bukalapak.com>
  #
  class Client

    NAMESPACE = "mothership:*".freeze

    attr_reader :instance, :identity, :lock, :monitor

    #
    # Initialize Central client.
    #
    # This will initialize monitor thread that monitor the changes
    # in redis namespsace.
    #
    # @param pool [Connection::Pool]       pool of redis
    # @param keys [Array<String, Symbol>]  keys of registered symbol or string namespace
    #
    def initialize(pool, keys=[])
      @pool = pool
      @identity = SecureRandom.uuid
      @instance = Hash.new
      @logger = Logger.new(STDOUT)
      @lock = Concurrent::ReentrantReadWriteLock.new

      @monitor = Thread.new do
        @pool.with do |client|
          client.psubscribe(NAMESPACE) do |on|
            on.psubscribe do |event, total|
              @logger.debug({context: :monitor, action: :psubscribe, event: event, total: total}.to_json)
            end

            on.pmessage do |pattern, event, message|
              _, message = event.split(":")
              unless message == self.identity
                @logger.debug({context: :monitor, pattern: pattern, event: event, message: message}.to_json)
                data = @client.hgetall(fnamespace)
                self.set(namespace, value)
              end
            end

            on.punsubscribe do |event, total|
              client.debug({context: :monitor, action: :punsubscribe, event: event, total: total}.to_json)
            end
          end
        end
      end

      values = Hash.new.tap do |values|
        @pool.with do |client|
          client.pipelined do |pipe|
            keys.each do |key|
              namespace = "mothership:#{key}"
              values[namespace] = pipe.hgetall(namespace)
            end
          end
        end
        values
      end
    end

    #
    # Massively set feature settings.
    #
    # @param namespace [Symbol]
    # @param value     [Hash]
    #
    def set!(namespace, value)
      fnamespace = "mothership:#{namespace}"
      self.set(namespace, value) do
        @pool.with do |client|
          client.multi do |multi|
            value.each do |key, value|
              multi.hset(fnamespace, key, value)
            end
          end
          @logger.debug({context: :central, action: :set!, params: [namespace, value.keys]}.to_json)
          client.publish(fnamespace, @identity)
          @logger.debug({context: :central, action: :publish, params: [:set!, fnamespace, @identity]}.to_json)
        end
      end
    end

    def set(namespace, value)
      fnamespace = "mothership:#{namespace}"
      namespace = namespace.to_sym
      @lock.with_write_lock do
        @instance[namespace] = value
        @logger.debug({context: :central, action: :set, params: [namespace, value.keys]}.to_json)
        yield if Kernel.block_given?
      end
    end

    def hset!(namespace, key, value)
      fnamespace = "mothership:#{namespace}"
      self.hset(namespace, key, value) do
        @pool.with do |client|
          client.hset(fnamespace, key, value)
          @logger.debug({context: :central, action: :hset!, params: [namespace, key, value.to_s]}.to_json)
          client.publish(fnamespace, @identity)
          @logger.debug({context: :central, action: :publish, params: [:hset!, fnamespace, @identity]}.to_json)
        end
      end
    end

    def hset(namespace, key, value)
      fnamespace = "mothership:#{namespace}"
      namespace = namespace.to_sym
      key = key.to_sym
      @lock.with_write_lock do
        @instance[namespace] = settings = @instance[namespace] || {}
        settings[key] = value
        @logger.debug({context: :central, action: :hset, params: [namespace, key, value.to_s]}.to_json)
        yield if Kernel.block_given?
      end
    end

    def join
      @monitor.join
    end

    def get(namespace)
      fnamespace = "mothership:#{namespace}"
      namespace = namespace.to_sym

      @lock.with_read_lock do
        @instance[namespace] || begin
                                  @pool.with do |client|
                                    client.hgetall(namespace)
                                  end
                                end
      end
    end
  end
end
