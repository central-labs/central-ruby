require 'logger'
require 'redis'
require 'connection_pool'
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

    attr_reader :instance, :identity, :lock, :monitor

    #
    # Initialize Central client.
    #
    # This will initialize monitor thread that monitor the changes
    # in redis namespsace.
    #
    # @param service [String]                 namespace of this service.
    # @param pool    [Connection::Pool]       pool of redis
    # @param keys    [Array<String, Symbol>]  keys of registered symbol or string namespace
    # @param logger  [Logger]                 logger to use for, default is STDOUT
    #
    def initialize(service, pool, keys=[], logger=nil)
      @pool = pool
      @service = service.freeze
      @identity = SecureRandom.uuid
      @instance = Hash.new
      @logger = logger || Logger.new(STDOUT)
      @lock = Concurrent::ReentrantReadWriteLock.new

      # Initialize monitor thread.
      # Monitor thread will use dedicated
      # 1 client from the pools forever.
      #
      @pool.with do |client|
        @monitor = Monitor.new(service, identity, client)
        @monitor.start
      end

      # update settings value.
      update
    end

    #
    # Update the settings values.
    #
    # This method will do I/O to redis.
    #
    def update
      @lock.with_write_lock do
        @instance = Hash.new.tap do |values|
          @pool.with do |client|
            client.pipelined do |pipe|
              keys.each do |key|
                namespace = "#{@service}:#{key}"
                values[namespace] = pipe.hgetall(namespace)
              end
            end
          end
          values
        end
      end
    end

    #
    # Massively set feature settings.
    #
    # This method will publish notification to redis.
    #
    # @param namespace [Symbol, String]
    # @param value     [Hash]
    #
    def set!(namespace, value)
      fnamespace = "#{@service}:#{namespace}"
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

    #
    # Locally massively set feature settings.
    #
    # This method will only set feature variables and won't publish
    # notification to redis.
    #
    # @param namespace [Symbol, String]
    # @param value     [Hash]
    #
    def set(namespace, value)
      fnamespace = "#{@service}:#{namespace}"
      namespace = namespace.to_sym
      @lock.with_write_lock do
        @instance[namespace] = value
        @logger.debug({context: :central, action: :set, params: [namespace, value.keys]}.to_json)
        yield if Kernel.block_given?
      end
    end

    #
    # Set per hash key, value settings.
    #
    # This method will publish notification to redis.
    #
    # @param namespace [Symbol, String]
    # @param key       [Symbol, String]
    # @param value     [Object, #to_s]
    #
    def hset!(namespace, key, value)
      fnamespace = "#{@service}:#{namespace}"
      self.hset(namespace, key, value) do
        @pool.with do |client|
          client.hset(fnamespace, key, value)
          @logger.debug({context: :central, action: :hset!, params: [namespace, key, value.to_s]}.to_json)
          client.publish(fnamespace, @identity)
          @logger.debug({context: :central, action: :publish, params: [:hset!, fnamespace, @identity]}.to_json)
        end
      end
    end

    #
    # Set namespace key, value.
    #
    # @param namespace [Symbol, String]
    # @param key       [Symbol, String]
    # @param value     [Object, #to_s]
    #
    def hset(namespace, key, value)
      fnamespace = "#{@service}:#{namespace}"
      namespace = namespace.to_sym
      key = key.to_sym
      @lock.with_write_lock do
        @instance[namespace] = settings = @instance[namespace] || {}
        settings[key] = value
        @logger.debug({context: :central, action: :hset, params: [namespace, key, value.to_s]}.to_json)
        yield if Kernel.block_given?
      end
    end

    #
    # Get feature variables.
    #
    # If it's undefined, it will fetch from redis.
    #
    # @param namespace [Symbol, String]
    #
    # @return Hash
    #
    def get(namespace)
      fnamespace = "#{@service}:#{namespace}"
      namespace = namespace.to_sym

      @lock.with_read_lock do
        @instance[namespace] || begin
                                  @pool.with do |client|
                                    client.hgetall(namespace)
                                  end
                                end
      end
    end

    #
    # Cleanup all resources
    #
    def destroy
      @monitor.stop!
    end
  end
end
