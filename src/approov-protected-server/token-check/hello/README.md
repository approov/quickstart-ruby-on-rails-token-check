# Approov Token Integration Example

This Approov integration example is from where the code example for the [Approov token check quickstart](/docs/APPROOV_TOKEN_QUICKSTART.md) is extracted, and you can use it as a playground to better understand how simple and easy it is to implement [Approov](https://approov.io) in a Ruby on Rails API server.

## TOC - Table of Contents

* [Why?](#why)
* [How it Works?](#how-it-works)
* [Requirements](#requirements)
* [Try the Approov Integration Example](#try-the-approov-integration-example)


## Why?

To lock down your API server to your mobile app. Please read the brief summary in the [Approov Overview](/OVERVIEW.md#why) at the root of this repo or visit our [website](https://approov.io/product) for more details.

[TOC](#toc---table-of-contents)


## How it works?

The Ruby on Rails API server is very simple and is defined in the project located at [src/approov-protected-server/token-check/hello](/src/approov-protected-server/token-check/hello). Take a look at the [Approov Middleware](/src/approov-protected-server/token-check/hello/app/middlewares/approov_middleware.rb) class, and search for the `verifyApproovToken()` function to see the simple code for the check.

For more background on Approov, see the [Approov Overview](/OVERVIEW.md#how-it-works) at the root of this repo.

[TOC](#toc---table-of-contents)


## Requirements

To run this example you will need to have Ruby and Rails installed. If you don't have then please follow the official installation instructions from [here](https://www.ruby-lang.org/en/documentation/installation/) to download and install them.

[TOC](#toc---table-of-contents)


## Try the Approov Integration Example

First, you need to create the `.env` file. From the `src/approov-protected-server/token-check/hello` folder execute:

```
cp .env.example .env
```

Second, you need to set the dummy secret in the `src/approov-protected-server/token-check/hello/.env` file as explained [here](/TESTING.md#the-dummy-secret).

Next, you need to install the dependencies. From the `src/approov-protected-server/token-check/hello` folder execute:

```text
bundle install
```

Now, you can run this example from the `src/approov-protected-server/token-check/hello` folder with:

```text
rails server --port 8002
```

> **NOTE:** If running the server inside a docker container add `--binding 0.0.0.0.`, otherwise the Ruby on Rails API server will not answer requests from outside the container, like the ones you may want to do from cURL or Postman to test the API.

Next, you can test that it works with:

```bash
curl -iX GET 'http://localhost:8002'
```

The response will be a `401` unauthorized request:

```text
HTTP/1.1 401 Unauthorized
Content-Type: application/json
Transfer-Encoding: chunked
```

The reason you got a `401` is because no Approoov token isn't provided in the headers of the request.

Finally, you can test that the Approov integration example works as expected with this [Postman collection](/TESTING.md#testing-with-postman) or with some cURL requests [examples](/TESTING.md#testing-with-curl).

[TOC](#toc---table-of-contents)


## Issues

If you find any issue while following our instructions then just report it [here](https://github.com/approov/quickstart-ruby-on-rails-token-check/issues), with the steps to reproduce it, and we will sort it out and/or guide you to the correct path.

[TOC](#toc---table-of-contents)


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

[TOC](#toc---table-of-contents)
