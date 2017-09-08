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
    # @param handlers [Hash]           instance of hash handlers
    # @param logger   [Logger]         logger, default is STDOUT
    #
    def initialize(service, identity, handlers,logger=nil)
      @service = service
      @identity = identity
      @logger = logger || Logger.new(STDOUT)
      @handlers = handlers
    end

    #
    # Start monitor thread.
    #
    def start
      @thread = Thread.new do
        @logger.info(tags: [:monitor, :thread, :perform, :start], message: "identity=#{@identity} action=perform start=start")
        perform
        @logger.info(tags: [:monitor, :thread, :perform, :done], message: "identity=#{@identity} action=perform state=done")
      end
    end

    #
    # Stop monitor thread.
    #
    def stop
      # TODO: create graceful stop
      @logger.info(tags: [:monitor, :thread, :stop], message: "identify=#{@identity} action=stop")
    end

    #
    # Forcefully stop monitor thread.
    #
    def stop!
      @monitor.kill
      @logger.info(tags: [:monitor, :thread, :stop, :forced], message: "identify=#{@identity} action=force_stop")
    end

    #
    # Restart monitor thread gracefully.
    #
    def restart
      @logger.info(tags: [:monitor, :thread, :restart], message: "identify=#{@identity} action=restart")
      stop; start
    end

    #
    # Perform real subscribing action.
    #
    def perform
      @logger.info({context: :monitor, action: :perfomed})
    end
  end
end
