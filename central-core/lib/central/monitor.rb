require 'logger'
require 'redis'

module Central
  #
  # Class that holds monitor logic to redis server.
  #
  # This class will use dedicated redis client (1 instance)
  # to subscribe any message from redis server.
  #
  class Monitor

    attr_reader :identity, :service

    #
    # @param service  [Symbol, String] service from `Central::Client`
    # @param identity [String]         identity of this instance of central client.
    # @param client   [Redis]          instance of `Redis`
    # @param logger   [Logger]         logger, default is STDOUT
    #
    def initialize(service, identity, client, logger=nil)
      @service = service
      @identity = identity
      @client = client
      @logger = logger || Logger.new(STDOUT)
    end

    #
    # Start monitor thread.
    #
    def start
      @thread = Thread.new { perform }
    end

    #
    # Stop monitor thread.
    #
    def stop
      # TODO: create graceful stop
      @logger.info({context: :monitor, action: :stop})
    end

    #
    # Forcefully stop monitor thread.
    #
    def stop!
      @monitor.kill
      @logger.info({context: :monitor, action: :stop!})
    end

    #
    # Restart monitor thread gracefully.
    #
    def restart
      stop; start
    end

    #
    # Perform real subscribing action.
    #
    def perform
      @logger.info({context: :monitor, action: :perfomed})
      @client.psubscribe("#{service}:*") do |callback|
        callback.psubscribe(self.on_subscribed)
        callback.pmessage(self.on_message)
        callback.punsubscribe(self.on_unsubscribed)
      end
    end

    #
    # Callback for subscribed event.
    #
    # @param event [String]  the subscribed event.
    # @param total [Integer] total number of subscriber.
    #
    protected
    def on_subscribed(event, total)
      @logger.debug({context: :monitor, action: :psubscribe, event: event, total: total}.to_json)
    end

    #
    # Callback for incoming message.
    #
    # @param pattern [String] the subscribed pattern channel.
    # @param event   [String] the actual channel.
    # @param message [String] the incoming message from redis.
    #
    def on_message(pattern, event, message)
      _, message = event.split(":")
      unless message == self.identity
        @logger.debug({context: :monitor, pattern: pattern, event: event, message: message}.to_json)
        data = @client.hgetall(fnamespace)
        self.set(namespace, value)
      end
    end

    #
    # Callback for unsubscribed event.
    #
    # @param event [String]  the unsubscribed event channel.
    # @param total [Integer] the total number of subscriber that active.
    #
    def on_unsubscribed(event, total)
      client.debug({context: :monitor, action: :punsubscribe, event: event, total: total}.to_json)
    end
  end
end
