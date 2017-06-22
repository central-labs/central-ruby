module Central
  module Feature
    # TODO: create Feature DSL like:
    #
    # @example Limit feature
    # class LimitFeature
    #
    #   TimeUnit = [:minute, :hour, :day, :week, :month].freeze
    #
    #   include Central::Feature
    #   include Central::Storage
    #
    #   DESCRIPTIONS = {
    #     time: """
    #     """,
    #     window: """
    #     """,
    #     amount: """
    #
    #     """
    #   }.freeze
    #
    #   feature :times, type: Integer, default: 5, description: DESCRIPTIONS[:time]
    #
    #   feature :window, type: TimeUnit, default: :hour, description: DESCRIPTIONS[:window]
    #
    #   feature :amount, type: Range, default: (1_000_000..2_000_000), description: DESCRIPTIONS[:amount]
    # end
    #
    module DSL

      UNEXPECTED_TYPE = "Unexpected type: reality: %s, expected: %s".freeze

      #
      # @param klass [Class]
      #
      def self.included(klass)
        unless klass.class_variable_defined? :@@_features
          klass.class_variable_set(:@@_features, {})
        end

        klass.extend ClassMethods
      end

      #
      # Namespace of feature class.
      #
      # @example
      #   SampleFeature.namespace == "sample_feature"
      #   A::SampleFeature.namespace == "a_sample_feature"
      #
      # @return [String]
      #
      def namespace
        self.class.namespace || self.class.name.split('::').join('_').downcase
      end

      module ClassMethods
        #
        # A macro to declare method at runtime initialization.
        #
        # It will declare :
        # - def "#{field}" field accessor & mutator
        # - def "#{field}_description"
        # - def "#{field}_type"
        # - def "#{field}_default"
        #
        # @example
        #   feature :times, type: Integer, default: 5, description: DESCRIPTIONS[:time]
        #
        # @!macro
        #
        def feature(*args)
          field, options = args

          self.define_singleton_method field do |_|
            self.features[field]
          end

          self.define_singleton_method "#{field}=" do |value|
            type = self.features[field][:type]
            raise TypeError.new(format(UNEXPECTED_TYPE, value.class.name, type.name)) unless value.is_a? type
            self.features[field] = value
          end

          self.define_singleton_method "#{field}" do |_|
            self.features[field] || self.features[field][:default]
          end

          self.define_singleton_method "#{field}_description" do |value|
            self.features[field][:description]
          end

          self.define_singleton_method "#{field}_type" do |value|
            self.features[field][:type]
          end

          self.define_singleton_method "#{field}_default" do |value|
            self.features[field][:default]
          end
        end

        #
        # Get or Set namespace of this feature manually.
        #
        # - Get if value isn't present?
        # - Set if value present?
        #
        # @example
        #   namespace
        #
        def namespace(*value)
          if value.present?
            unless klass.class_variable_defined? :@@_feature_namespace
              klass.class_variable_set(:@@_feature_namespace, value.first)
            end
          else
            klass.class_variable_get(:@@_feature_namespace)
          end

        end

        protected
        #
        # @return [Hash]
        #
        def features
          self.class_variable_get(:@@_features)
        end
        #
        # @return [Array<Symbol>]
        #
        #
        def attributes
          self.features.keys
        end
      end
    end
  end
end
