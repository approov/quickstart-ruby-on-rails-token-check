# frozen_string_literal: true

require "base64"
require "digest"
require "json"
require "jwt"
require "rack/utils"

class ApproovState
  PLACEHOLDER_SECRET = "approov_base64url_secret_here"
  APPROOV_HEADER = "Approov-Token"
  AUTHORIZATION_HEADER = "Authorization"
  SESSION_ID_HEADER = "SessionId"

  @mutex = Mutex.new
  @approov_enabled = true
  @token_binding_enabled = true

  class << self
    def approov_enabled?
      @mutex.synchronize { @approov_enabled }
    end

    def token_binding_enabled?
      @mutex.synchronize { @token_binding_enabled }
    end

    def enable_approov!
      @mutex.synchronize do
        @approov_enabled = true
        @token_binding_enabled = true
      end
    end

    def disable_approov!
      @mutex.synchronize do
        @approov_enabled = false
        @token_binding_enabled = false
      end
    end

    def enable_token_binding!
      @mutex.synchronize { @token_binding_enabled = true }
    end

    def disable_token_binding!
      @mutex.synchronize { @token_binding_enabled = false }
    end

    def state_payload
      @mutex.synchronize do
        {
          "approovEnabled" => @approov_enabled,
          "tokenBindingEnabled" => @token_binding_enabled
        }
      end
    end
  end
end

class ApproovMiddleware
  HTTP_STATUS_OK = 200
  HTTP_STATUS_UNAUTHORIZED = 401
  LOGGABLE_STATUSES = [HTTP_STATUS_OK, HTTP_STATUS_UNAUTHORIZED].freeze

  PROTECTED_ROUTES = {
    "/token-check" => [].freeze,
    "/token-binding" => [ApproovState::AUTHORIZATION_HEADER].freeze,
    "/token-double-binding" => [ApproovState::AUTHORIZATION_HEADER, ApproovState::SESSION_ID_HEADER].freeze
  }.freeze

  ValidationError = Struct.new(
    :reason,
    :required_headers,
    :error_message,
    :exception_class,
    keyword_init: true
  )

  ValidationResult = Struct.new(:ok, :claims, :error, keyword_init: true) do
    def success?
      ok
    end
  end

  class TokenValidator
    SecretConfigurationError = Class.new(StandardError)

    class << self
      def validate_required_secret!
        required_secret
      end

      def required_secret
        @required_secret ||= load_required_secret
      end

      private

      def load_required_secret
        raw_secret = ENV.fetch("APPROOV_BASE64URL_SECRET", "").strip

        if raw_secret.empty? || raw_secret == ApproovState::PLACEHOLDER_SECRET
          Rails.logger.error("Required secret is not set")
          raise SecretConfigurationError, "Required secret is not set"
        end

        Base64.urlsafe_decode64(raw_secret)
      rescue ArgumentError
        Rails.logger.error("Required secret is invalid")
        raise SecretConfigurationError, "Required secret is invalid"
      end
    end

    def validate(path:, request:)
      bound_headers = PROTECTED_ROUTES.fetch(path, [])
      required_headers = required_headers_for(bound_headers)

      token = header_value(request, ApproovState::APPROOV_HEADER)
      return failure(:missing_approov_token, required_headers) if token.nil? || token.empty?

      claims = verify_approov_token(token)

      if ApproovState.token_binding_enabled? && !bound_headers.empty?
        binding_value = extract_binding_value(request, bound_headers)
        return failure(:missing_binding_header, required_headers) if binding_value.nil? || binding_value.empty?
        return failure(:binding_mismatch, required_headers) unless binding_valid?(binding_value, claims["pay"])
      end

      ValidationResult.new(ok: true, claims: claims)
    rescue JWT::DecodeError,
           JWT::VerificationError,
           JWT::ExpiredSignature,
           JWT::IncorrectAlgorithm,
           ArgumentError => e
      failure(:token_verification_failed, required_headers, e.message, e.class.name)
    end

    def required_headers_for_path(path)
      bound_headers = PROTECTED_ROUTES.fetch(path, [])
      required_headers_for(bound_headers)
    end

    private

    def verify_approov_token(token)
      claims, = JWT.decode(
        token,
        self.class.required_secret,
        true,
        algorithms: ["HS256"],
        verify_expiration: false
      )

      validate_expiration!(claims)
      claims
    end

    def validate_expiration!(claims)
      exp = claims["exp"]
      raise JWT::DecodeError, "Approov token missing expiration." if exp.nil?

      expiration_time = Time.at(Integer(exp)).utc
      raise JWT::DecodeError, "Approov token expired." if expiration_time <= Time.now.utc
    rescue ArgumentError, TypeError
      raise JWT::DecodeError, "Approov token has invalid expiration."
    end

    def extract_binding_value(request, bound_headers)
      binding_components = bound_headers.map { |header| header_value(request, header) }
      return nil if binding_components.any? { |value| value.nil? || value.empty? }

      construct_binding_input(binding_components)
    end

    def binding_valid?(binding_value, pay_claim)
      return false unless pay_claim.is_a?(String)

      normalized_pay_claim = pay_claim.strip
      return false if normalized_pay_claim.empty?

      computed_pay = ApproovMiddleware.binding_hash(binding_value)
      secure_equal?(computed_pay, normalized_pay_claim)
    end

    def header_value(request, header_name)
      rack_name = "HTTP_#{header_name.upcase.tr('-', '_')}"
      value = request.get_header(rack_name) || request.get_header(header_name)
      return nil unless value.is_a?(String)

      stripped = value.strip
      stripped.empty? ? nil : stripped
    end

    def required_headers_for(bound_headers)
      return [ApproovState::APPROOV_HEADER] if !ApproovState.token_binding_enabled? || bound_headers.empty?

      [ApproovState::APPROOV_HEADER, *bound_headers]
    end

    def secure_equal?(left, right)
      return false unless left.bytesize == right.bytesize

      Rack::Utils.secure_compare(left, right)
    end

    def construct_binding_input(binding_components)
      binding_components.join
    end

    def failure(reason, required_headers, error_message = nil, exception_class = nil)
      ValidationResult.new(
        ok: false,
        error: ValidationError.new(
          reason: reason.to_s,
          required_headers: required_headers,
          error_message: error_message,
          exception_class: exception_class
        )
      )
    end
  end

  class << self
    def validate_required_secret!
      TokenValidator.validate_required_secret!
    end

    def binding_hash(binding_value)
      Base64.strict_encode64(Digest::SHA256.digest(binding_value))
    end
  end

  def initialize(app)
    @app = app
    @validator = TokenValidator.new
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    path = request.path

    return @app.call(env) unless PROTECTED_ROUTES.key?(path)

    required_headers = @validator.required_headers_for_path(path)

    unless ApproovState.approov_enabled?
      status, headers, body = @app.call(env)
      log_response(request: request, status: status, summary: "approov_disabled", required_headers: required_headers)
      return [status, headers, body]
    end

    validation = @validator.validate(path: path, request: request)
    unless validation.success?
      log_validation_failure(request, validation.error)
      return unauthorized_response
    end

    env["approov.token_claims"] = validation.claims

    status, headers, body = @app.call(env)
    log_response(request: request, status: status, summary: "approov_ok", required_headers: required_headers)

    [status, headers, body]
  end

  private

  def unauthorized_response
    [HTTP_STATUS_UNAUTHORIZED, { "Content-Type" => "application/json" }, [{ error: "Unauthorized" }.to_json]]
  end

  def log_validation_failure(request, error)
    log_response(
      request: request,
      status: HTTP_STATUS_UNAUTHORIZED,
      summary: "approov_failed:#{error.reason}",
      required_headers: error.required_headers,
      error: error.error_message,
      exception: error.exception_class
    )
  end

  def log_response(request:, status:, summary:, required_headers:, error: nil, exception: nil)
    return unless LOGGABLE_STATUSES.include?(status)

    effective_summary = if status == HTTP_STATUS_UNAUTHORIZED && !summary.start_with?("approov_failed:")
                          "approov_failed:downstream_unauthorized"
                        else
                          summary
                        end

    log_payload = {
      event: "http.request.completed",
      summary: effective_summary,
      method: request.request_method,
      path: request.path,
      status: status,
      ip: request.remote_ip,
      port: request.port,
      required_headers: required_headers
    }.merge(ApproovState.state_payload)

    log_payload[:error] = error if error
    log_payload[:exception] = exception if exception

    if error || exception
      Rails.logger.warn(log_payload.to_json)
      return
    end

    Rails.logger.info(log_payload.to_json)
  end
end
