# frozen_string_literal: true

class ApproovController < ApplicationController
  def home
    render json: info_payload("Approov demo API is running on port #{request.port}.")
  end

  def approov_state
    render json: ApproovState.state_payload
  end

  def enable_approov
    ApproovState.enable_approov!
    render json: ApproovState.state_payload
  end

  def disable_approov
    ApproovState.disable_approov!
    render json: ApproovState.state_payload
  end

  def enable_token_binding
    ApproovState.enable_token_binding!
    render json: ApproovState.state_payload
  end

  def disable_token_binding
    ApproovState.disable_token_binding!
    render json: ApproovState.state_payload
  end

  def unprotected
    render json: info_payload("Unprotected endpoint '/unprotected'; no Approov checks performed.")
  end

  def token_check
    render json: info_payload("Protected endpoint '/token-check'; Approov token verified.")
  end

  def token_binding
    response = info_payload("Protected endpoint '/token-binding'; Approov token binding enforced.")
    response["authorizationHeaderPresent"] = header_present?(ApproovState::AUTHORIZATION_HEADER)
    render json: response
  end

  def token_double_binding
    response = info_payload("Protected endpoint '/token-double-binding'; dual token binding enforced.")
    response["authorizationHeaderPresent"] = header_present?(ApproovState::AUTHORIZATION_HEADER)
    response["sessionIdHeaderPresent"] = header_present?(ApproovState::SESSION_ID_HEADER)
    render json: response
  end

  private

  def info_payload(details)
    ApproovState.state_payload.merge("details" => details)
  end

  def header_present?(header_name)
    value = request.headers[header_name]
    value.is_a?(String) && !value.strip.empty?
  end
end
