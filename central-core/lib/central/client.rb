module Central
  #
  # This module contains all implementation specifics
  # for pubsub client implementation.
  #
  module Client

    def self.create(type, *args)
      case type
      when :redis then
        require 'central/client/redis'
        Central::Client::Redis.new(*args)
      when :consul then
        require 'central/client/consul'
        Central::Client::Consul.new(*args)
      end
    end
  end
end
