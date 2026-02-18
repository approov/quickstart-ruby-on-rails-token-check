# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_support/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"

require_relative "../app/middleware/approov_middleware"

Bundler.require(*Rails.groups)

module ApproovQuickstart
  class Application < Rails::Application
    config.load_defaults 7.1

    config.api_only = true
    config.log_level = :info
    config.action_controller.perform_caching = false
    config.cache_store = :null_store

    config.action_dispatch.default_headers = config.action_dispatch.default_headers.merge(
      "Cache-Control" => "no-store",
      "Pragma" => "no-cache",
      "Expires" => "0"
    )

    config.autoload_paths << Rails.root.join("app", "middleware")
    config.eager_load_paths << Rails.root.join("app", "middleware")

    config.middleware.delete Rack::ETag
    config.middleware.delete Rack::ConditionalGet
    config.middleware.use ApproovMiddleware
  end
end
