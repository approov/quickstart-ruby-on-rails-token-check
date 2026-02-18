# frozen_string_literal: true

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  config.log_level = :info
  config.action_dispatch.show_exceptions = false

  config.force_ssl = false
end
