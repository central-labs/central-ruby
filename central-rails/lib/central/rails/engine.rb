module Central
  module Rails
    class Engine < ::Rails::Engine
      isolate_namespace Central::Rails

      #
      # Initialize all features.
      #
      initializer "central.init_features" do |app|
        Rails.logger.info({context: :central, action: :init_all})
        Dir[Rails.root.join(path["app"], 'features', '**', '*.rb')].each do |file|
          require_once file
          Rails.logger.info({context: :central, action: :load_feature, message: { file: file }})
        end
      end
    end
  end
end
