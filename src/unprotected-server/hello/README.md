# Unprotected Server Example

The unprotected example is the base reference to build the [Approov protected servers](/src/approov-protected-server/). This a very basic Hello World Ruby on Rails API server.


## TOC - Table of Contents

* [Why?](#why)
* [How it Works?](#how-it-works)
* [Requirements](#requirements)
* [Try It](#try-it)


## Why?

To be the starting building block for the [Approov protected servers](/src/approov-protected-server/), that will show you how to lock down your API server to your mobile app. Please read the brief summary in the [README](/README.md#why) at the root of this repo or visit our [website](https://approov.io/product.html) for more details.

[TOC](#toc---table-of-contents)


## How it works?

The Ruby on Rails API server is very simple and is defined in the project located at [src/unprotected-server/hello](/src/unprotected-server).

The server only replies to the endpoint `/` with the message:

```json
{"message": "Hello, World!"}
```

[TOC](#toc---table-of-contents)


## Requirements

To run this example you will need to have Ruby and Rails installed. If you don't have then please follow the official installation instructions from [here](https://www.ruby-lang.org/en/documentation/installation/) to download and install them.

[TOC](#toc---table-of-contents)


## Try It

First, you need to install the dependencies. From the `src/unprotected-server/hello` folder execute:

```text
bundle install
```

Now, you can run this example from the `src/unprotected-server/hello` folder with:

```text
rails server --port 8002
```

> **NOTE:** If running the server inside a docker container add `--binding 0.0.0.0.`, otherwise the Laravel server will not answer requests from outside the container, like the ones you may want to do from cURL or Postman to test the API.

Finally, you can test that it works with:

```text
curl -iX GET 'http://localhost:8002'
```

The response will be:

```text
HTTP/1.1 200 OK
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
X-Download-Options: noopen
X-Permitted-Cross-Domain-Policies: none
Referrer-Policy: strict-origin-when-cross-origin
Content-Type: application/json; charset=utf-8
ETag: W/"8811a6f55cb434d10921bccf7108016d"
Cache-Control: max-age=0, private, must-revalidate
X-Request-Id: 59a646e0-360f-4408-9e0c-eb6a3413f5fc
X-Runtime: 0.027943
Transfer-Encoding: chunked

{"message":"Hello, World!"}
```

[TOC](#toc---table-of-contents)
