Rails.application.routes.draw do
  mount Central::Rails::Engine => "/central-rails"
end
