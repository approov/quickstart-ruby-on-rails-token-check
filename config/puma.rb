# frozen_string_literal: true

max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
threads max_threads_count, max_threads_count

port ENV.fetch("HTTP_PORT", 8080)
environment ENV.fetch("RAILS_ENV", "development")

plugin :tmp_restart
