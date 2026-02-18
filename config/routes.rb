# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "approov#home"

  get "/approov-state", to: "approov#approov_state"
  post "/approov/enable", to: "approov#enable_approov"
  post "/approov/disable", to: "approov#disable_approov"

  post "/token-binding/enable", to: "approov#enable_token_binding"
  post "/token-binding/disable", to: "approov#disable_token_binding"

  get "/unprotected", to: "approov#unprotected"
  get "/token-check", to: "approov#token_check"
  get "/token-binding", to: "approov#token_binding"
  get "/token-double-binding", to: "approov#token_double_binding"
end
