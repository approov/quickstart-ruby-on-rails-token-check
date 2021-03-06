# Approov Token Binding Integration Example

This Approov integration example is from where the code example for the [Approov token binding check quickstart](/docs/APPROOV_TOKEN_BINDING_QUICKSTART.md) is extracted, and you can use it as a playground to better understand how simple and easy it is to implement [Approov](https://approov.io) in a Ruby on Rails API server.

## TOC - Table of Contents

* [Why?](#why)
* [How it Works?](#how-it-works)
* [Requirements](#requirements)
* [Try the Approov Integration Example](#try-the-approov-integration-example)


## Why?

To lock down your API server to your mobile app. Please read the brief summary in the [README](/README.md#why) at the root of this repo or visit our [website](https://approov.io/product.html) for more details.

[TOC](#toc---table-of-contents)


## How it works?

The Ruby on Rails API server is very simple and is defined in the project [src/approov-protected-server/token-binding-check/hello](/src/approov-protected-server/token-binding-check/hello). Take a look at the [Approov Middleware](/src/approov-protected-server/token-binding-check/hello/app/middlewares/approov_middleware.rb) class, and search for the `verifyApproovToken()` and `verifyApproovTokenBinding()` functions to see the simple code for the checks.

For more background on Approov, see the overview in the [README](/README.md#how-it-works) at the root of this repo.

[TOC](#toc---table-of-contents)


## Requirements

To run this example you will need to have Ruby and Rails installed. If you don't have then please follow the official installation instructions from [here](https://www.ruby-lang.org/en/documentation/installation/) to download and install them.

[TOC](#toc---table-of-contents)


## Try the Approov Integration Example

First, you need to create the `.env` file. From the `src/approov-protected-server/token-binding-check/hello` folder execute:

```
cp .env.example .env
```

Second, you need to set the dummy secret in the `src/approov-protected-server/token-binding-check/hello/.env` file as explained [here](/README.md#the-dummy-secret).

Next, you need to install the dependencies. From the `src/approov-protected-server/token-binding-check/hello` folder execute:

```text
bundle install
```

Now, you can run this example from the `src/approov-protected-server/token-binding-check/hello` folder with:

```text
rails server --port 8002
```

> **NOTE:** If running the server inside a docker container add `--binding 0.0.0.0.`, otherwise the Ruby on Rails API server will not answer requests from outside the container, like the ones you may want to do from cURL or Postman to test the API.

Finally, you can test that the Approov integration example works as expected with this [Postman collection](/README.md#testing-with-postman) or with some cURL requests [examples](/README.md#testing-with-curl).

[TOC](#toc---table-of-contents)
