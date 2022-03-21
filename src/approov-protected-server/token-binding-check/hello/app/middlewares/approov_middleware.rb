class ApproovMiddleware
    def initialize app
        @app = app

        if not ENV['APPROOV_BASE64_SECRET']
            raise "Missing in the .env file the value for the variable: APPROOV_BASE64_SECRET"
        end

        @APPROOV_SECRET = Base64.decode64(ENV['APPROOV_BASE64_SECRET'])
    end

    def call env
        # Make the code thread safe by duplicating the object
        dup._call env
    end

    def _call env
        # We return 401 with an empty body because we don't want to give clues
        # to the attacker about why he is failing the request, and you can go
        # even further and return a 400.
        invalid_response = [401, {"Content-Type" => "application/json"}, []]

        request = Rack::Request.new env

        approov_token_claims = verifyApproovToken(request)

        if not approov_token_claims
            return invalid_response
        end

        if not verifyApproovTokenBinding(request, approov_token_claims)
            return invalid_response
        end

        # Allow later reuse of the Approov token claims in request life cycle.
        env["APPROOV_TOKEN_CLAIMS"] = approov_token_claims

        return @app.call(env)
    end

    def verifyApproovToken request
        begin
            approov_token = request.get_header "HTTP_APPROOV_TOKEN"

            if not approov_token
                # You may want to add some logging here
                # Rails.logger.debug 'Missing the Approov token header!'
                return nil
            end

            options = { algorithm: 'HS256' }
            approov_token_claims, header = JWT.decode approov_token, @APPROOV_SECRET, true, options

            return approov_token_claims

        rescue JWT::DecodeError => e
            # You may want to add some logging here
            # Rails.logger.debug e
            return nil
        rescue JWT::ExpiredSignature => e
            # You may want to add some logging here
            # Rails.logger.debug e
            return nil
        rescue JWT::InvalidIssuerError => e
            # You may want to add some logging here
            # Rails.logger.debug e
            return nil
        rescue JWT::InvalidIatError => e
            # You may want to add some logging here
            # Rails.logger.debug e
            return nil
        end

        # You may want to add some logging here
        # Rails.logger.debug 'Whoops, unknown failure when verifying the Approov token!'
        return nil
    end

    def verifyApproovTokenBinding request, approov_token_claims
        if not approov_token_claims['pay']
            # You may want to add some logging here
            # Rails.logger.debug 'Missing Approov token binding claim in the Approov token.'
            return false
        end

        # We use the Authorization token, but feel free to use another header in
        # the request. Beqar in mind that it needs to be the same header used in the
        # mobile app to qbind the request with the Approov token.
        token_binding_header = request.get_header 'HTTP_AUTHORIZATION'

        if not token_binding_header
            # You may want to add some logging here
            # Rails.logger.debug 'Missing the token binding header in the request headers.'
            return false
        end

        # We need to hash and base64 encode the token binding header, because that's
        # how it was included in the Approov token on the mobile app.
        token_binding_header_encoded = Digest::SHA256.base64digest token_binding_header

        if not approov_token_claims['pay'] === token_binding_header_encoded
            # You may want to add some logging here
            # Rails.logger.debug 'Token binding not matching.'
            return false
        end

        return true
    end
end
