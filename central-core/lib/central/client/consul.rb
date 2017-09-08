require 'logger'
require 'net/http/persistent'
require 'concurrent-edge'
require 'connection_pool'
require 'base64'

class Central::Client::Consul

  LIST_ENDPOINT = '%s/v1/event/list?name=feature/changed&service=%s'.freeze
  WATCH_ENDPOINT = '%s/v1/event/list?index=%d&name=%s&service=%s'.freeze
  UPDATE_ENDPOINT = '%s/v1/event/fire/%s?service=%s'.freeze
  FILTER_PATTERN_TAG = /\/([a-zA-Z0-9\_\-]+)\/([a-zA-Z0-9\_\-]+)\/([a-zA-Z0-9\_\-\/]+)/.freeze

  attr_reader :instance, :identity, :lock, :monitor

  State = Struct.new(:id, :time)
  Host = Struct.new(:addr, :port)

  class Monitor < Central::Monitor
    attr_reader :identity, :service

    def initialize(service, identity, host, handlers, logger=nil)
      super(service.freeze, identity.freeze, logger, handlers)
      @host = host
      @client = Net::HTTP::Persistent.new()
    end

    def perform
      state = nil
      loop do
        action = if state.nil?
                   Net::HTTP::Get.new(format(LIST_ENDPOINT, "#{@host.addr}:#{@host.port}", service))
                 else
                   Net::HTTP::Get.new(format(WATCH_ENDPOINT, state.id, service))
                 end

        response = @client.request(action.path)

        if response.code != '200' && response.body.empty?
          state = nil
          sleep 1
          next
        end

        events = JSON.parse(body)

        if events.empty?
          state = nil
          sleep 1
          next
        end

        events.each do |event|
          next if (state || state.time > event['LTime']) && state
          group = FILTER_PATTERN_TAG.match(event['TagFilter'])
          event = Central::Event.new(
            event['service'] = group[1],
            event['identity'] = group[2],
            event['namespace'] = group[3]
          )
          next if event.service == @service ||
                  event.identity == @identity

          @handlers[:message].call(event)

          state = State.new(index_of(event), event['LTime'])
        end
      end
    end

    private
    def payload_of(event)
      payload = event['Payloads']
      Base64.decode64(payload)
    end

    def index_of(event)
      id = event['ID']
      lower = id[0..7] + id[9..12] + id[14..17]
      upper = id[19..22] + id[24..35]
      lower = lower.to_i(16)
      upper = upper.to_i(16)
      lower ^ upper
    end
  end

  def initialize(service, pool, keys=[], logger=nil)
    @pool = pool
    @service = service.freeze
    @identity = SecureRandom.uuid
    @instance = Hash.new
    @logger = logger || Logger.new(STDOUT)
    @lock = Concurrent::ReentrantReadWriteLock.new

    @pool.with do |client|
      @monitor = Monitor.new(service, identity, client)
      @monitor.start
    end

    update
  end

  def perform

  end

  def update

  end

  def set!(feature, value)

  end

  def set(namespace, value)
    namespace = "#{@service}:#{feature}".to_sym
    @locks[namespace].with_write_lock do
      @storage[namespace] = value
      @logger.debug({context: :central, action: :set, params: [namespace, value.keys]}.to_json)
      yield if Kernel.block_given?
    end
  end

  def destroy
    @monitor.stop!
  end

  protected
  def publish(event)

  end

end
