# Approov QuickStart - Ruby on Rails Token Check

[Approov](https://approov.io) is an API security solution used to verify that requests received by your backend services originate from trusted versions of your mobile apps.

This repo implements the Approov server-side request verification code in Ruby, which performs the verification check before allowing valid traffic to be processed by the API endpoint.

This is an Approov integration quickstart example for the Ruby on Rails framework. If you are looking for another Ruby integration you can check our list of [quickstarts](https://approov.io/docs/latest/approov-integration-examples/backend-api/), and if you don't find what you are looking for, then please let us know [here](https://approov.io/contact). Meanwhile, you can always use the framework agnostic [quickstart example](https://github.com/approov/quickstart-ruby-on-rails-token-check) for Ruby, and you may find that's easily adaptable to your framework of choice.


## Approov Integration Quickstart

The quickstart was tested with the following Operating Systems:

* Ubuntu 20.04
* MacOS Big Sur
* Windows 10 WSL2 - Ubuntu 20.04

First, setup the [Approov CLI](https://approov.io/docs/latest/approov-installation/index.html#initializing-the-approov-cli).

Now, register the API domain for which Approov will issues tokens:

```bash
approov api -add api.example.com
```

> **NOTE:** By default a symmetric key (HS256) is used to sign the Approov token on a valid attestation of the mobile app for each API domain it's added with the Approov CLI, so that all APIs will share the same secret and the backend needs to take care to keep this secret secure.
>
> A more secure alternative is to use asymmetric keys (RS256 or others) that allows for a different keyset to be used on each API domain and for the Approov token to be verified with a public key that can only verify, but not sign, Approov tokens.
>
> To implement the asymmetric key you need to change from using the symmetric HS256 algorithm to an asymmetric algorithm, for example RS256, that requires you to first [add a new key](https://approov.io/docs/latest/approov-usage-documentation/#adding-a-new-key), and then specify it when [adding each API domain](https://approov.io/docs/latest/approov-usage-documentation/#keyset-key-api-addition). Please visit [Managing Key Sets](https://approov.io/docs/latest/approov-usage-documentation/#managing-key-sets) on the Approov documentation for more details.

Next, enable your Approov `admin` role with:

```bash
eval `approov role admin`
````

For the Windows powershell:

```bash
set APPROOV_ROLE=admin:___YOUR_APPROOV_ACCOUNT_NAME_HERE___
```

Now, get your Approov Secret with the [Approov CLI](https://approov.io/docs/latest/approov-installation/index.html#initializing-the-approov-cli):

```bash
approov secret -get base64
```

Next, add the [Approov secret](https://approov.io/docs/latest/approov-usage-documentation/#account-secret-key-export) to your project `.env` file:

```env
APPROOV_BASE64_SECRET=approov_base64_secret_here
```

Now, add to your Gemfile the [dotenv-rails](https://github.com/bkeepers/dotenv) gem to automatically load the Approov secret:

```ruby
gem 'dotenv-rails', '~> 2.7.6'
```

Next, to check the Approov token you need to add the [jwt/ruby-jwt](https://github.com/jwt/ruby-jwt) gem to your Gemfile:

```ruby
gem 'jwt', '~> 2.2.2'
```

Now, run the installer:

```bash
bundle install
```

Next, add the [Approov Middleware](/src/approov-protected-server/token-check/hello/app/middlewares/approov_middleware.rb) class to your project at `app/middlewares/approov_middleware.rb`:

```ruby
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
end
```

> **NOTE:** When the Approov token validation fails we return a `401` with an empty body, because we don't want to give clues to an attacker about the reason the request failed, and you can go even further by returning a `400`.


Now, add the [Approov Middleware](/src/approov-protected-server/token-check/hello/app/middlewares/approov_middleware.rb) to your Ruby on Rails application middleware configuration at [config/application.rb](/src/approov-protected-server/token-binding-check/hello/config/application.rb):

```ruby
# Inserted as the first middleware to protect your server from wasting
# resources in processing requests not having a valid Approov token. This
# increases availability for your users during peak time or in the event of a
# DoS attack.
config.middleware.insert_before ActionDispatch::HostAuthorization, ApproovMiddleware
```

Not enough details in the bare bones quickstart? No worries, check the [detailed quickstarts](QUICKSTARTS.md) that contain a more comprehensive set of instructions, including how to test the Approov integration.


## More Information

* [Approov Overview](OVERVIEW.md)
* [Detailed Quickstarts](QUICKSTARTS.md)
* [Examples](EXAMPLES.md)
* [Testing](TESTING.md)


### System Clock

In order to correctly check for the expiration times of the Approov tokens is very important that the backend server is synchronizing automatically the system clock over the network with an authoritative time source. In Linux this is usually done with a NTP server.


## Issues

If you find any issue while following our instructions then just report it [here](https://github.com/approov/quickstart-ruby-on-rails-token-check/issues), with the steps to reproduce it, and we will sort it out and/or guide you to the correct path.


## Useful Links

If you wish to explore the Approov solution in more depth, then why not try one of the following links as a jumping off point:

* [Approov Free Trial](https://approov.io/signup)(no credit card needed)
* [Approov Get Started](https://approov.io/product/demo)
* [Approov QuickStarts](https://approov.io/docs/latest/approov-integration-examples/)
* [Approov Docs](https://approov.io/docs)
* [Approov Blog](https://approov.io/blog/)
* [Approov Resources](https://approov.io/resource/)
* [Approov Customer Stories](https://approov.io/customer)
* [Approov Support](https://approov.io/contact)
* [About Us](https://approov.io/company)
* [Contact Us](https://approov.io/contact)
