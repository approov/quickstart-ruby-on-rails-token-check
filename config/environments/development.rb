# frozen_string_literal: true

Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  config.log_level = :info
  # Show Rails + middleware logs in the Puma terminal when running locally.
  stdout_logger = ActiveSupport::Logger.new($stdout)
  stdout_logger.formatter = config.log_formatter
  config.logger = ActiveSupport::TaggedLogging.new(stdout_logger)

  config.action_dispatch.show_exceptions = true
end
