module Central
  module Rails
    class Engine < ::Rails::Engine
      isolate_namespace Central::Rails
    end
  end
end
