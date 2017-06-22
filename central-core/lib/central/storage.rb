require 'mongoid'

module Central
  #
  # Mongoid class that store Feature options.
  #
  class Storage
    include Mongoid::Document
    include Mongoid::Timestamps

    field :team,    type: String
    field :feature, type: String
    field :name,    type: String
    field :data,    type: Hash
    field :active,  type: Boolean

    index({team: 1},    background: true)
    index({feature: 1}, background: true)
    index({name: 1},    background: true)
    index({active: 1},  background: true)
  end

  #
  # Mongoid class that store feature options changed.
  #
  # Used for auditing.
  #
  # TODO: better audit logs.
  #
  class Audit
    include Mongoid::Document
    include Mongoid::Timestamps

    field :actor_id,  type: Integer
  end

  #
  #
  # This module will made any `Feature` class to be
  # instanceable and have a defaults.
  #
  # @example
  # class SampleFeature
  #
  # end
  #
  module Persistent

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    def storage
      Central::Storage.where(feature: namespace)
    end

    def default
      Central::Storage.where(feature: namespace, active: true)
    end

    module ClassMethods
      def loggable(value)
      end

      #
      # Search feature based on name
      #
      # @param name [String]
      #
      # @return [Central::Storage]
      #
      def search(name)
        Central::Storage.where(feature: namespace, name: name)
      end
    end
  end
end
