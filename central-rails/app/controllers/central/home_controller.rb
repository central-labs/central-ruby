module Central
  class HomeController <  Central::Rails::ApplicationController

    before_action do |action|
      # HACK: check central configuration
      Rails::Application.config.central_check.call(action.request)
    end

    DEFAULT_PAGE = 1
    PAGE_SIZE = 20

    #
    # TODO: Implement this on the mothership
    #
    def index
      # list all features
      options = _params_page
      @features = Central::Storage
                    .skip(options[:page] * options[:size])
                    .limit(options[:size])
    end

    # TODO: find better way to do search
    def search
      @features = Central::Storage.search(_params_search)
    end

    #
    # TODO: Implement this on the mothership
    #
    def new
      # TODO: view
      @feature = Central::Storage.new
    end

    #
    # TODO: Implement this on the mothership
    #
    def show
      # TODO: view
      @feature = Central::Storage.find_by(_params_select)
    end

    def edit
      # TODO: view
      @feature = Central::Storage.find_by(_params_select)
    end

    def update
      fields = _params_update
      feature = Central::Storage.find_by(_params_select)
      feature.update(fields)
    end

    private
    def _params_page
      options = params.permit(:page, :size).select(:page, :size)
      options[:page] ||= DEFAULT_PAGE
      options[:size] ||= PAGE_SIZE
      options
    end

    def _params_select
      params.permit(:team, :feature).select(:team, :feature)
    end

    def _params_update
      namespace = params.select(:feature)
      klass = _lookup(namespace)
      params.permit(*klass.attributes)
    end

    def _params_search
      params.permit(:name, :feature).select(:name, :feature)
    end

    def _lookup(namespace)
      # TODO:
      begin
        Object.const_get(namespace.camelize)
      rescue StandardError => e
        # TODO: log error comes from wrong lookup namespace
        Rails.logger.error({})
        nil
      end
    end
  end
end
