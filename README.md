# push-api-example

## Overview

This is a reference implementation in Ruby of [Fundera's](https://www.fundera.com) "Push API" specification.  Fundera's lender partners can implement an API according to this spec to achieve easy integration with Fundera's business loan marketplace.

The specification is here:
[Fundera -- Prequalification & Underwriting APIs 2016](https://docs.google.com/document/d/1cG1Q4vtQ4y3AGq-bO0u0Q9KuicqqHoFOFQ6Xry76G3E/edit)

This project implements the "Prequalification API" there described.

## Install and Run

To run the reference server, you need Ruby 2.0+ and the Sinatra gem.  To install Sinatra:

    gem install sinatra

Then in the project directory:

    ruby app.rb

Or, use bundler:

    bundle install
    bundle exec ruby app.rb

To use an environment other than "development":

    RACK_ENV=staging ruby app.rb

Or:

     RACK_ENV=staging bundle exec ruby app.rb

This will run an HTTP service at http://localhost:4567.

To send a test request to the server with curl:

    curl -u development:abc123 -d @request.json http://localhost:4567/api/v1/prequalify

Where "request.json" contains the JSON request to send.  See the spec for examples.

## Features

This implementation demonstrates the following features mentioned in the spec:

* Authorization via HTTP Basic Auth.
* HTTP statuses for malformed requests and other errors.
* Handling and validating the many data fields, many of them optional, sent in API requests.
* Storing requests and producing a preapproval decision, with or without provisional loan offers.
* Multiple environments (development, staging, production).
* Triggering test responses with special field values.
* Providing an optional URL on each loan offer, via which loan customers can visit the API implementer's site to claim an offer.

Additionally, the server implements a trivial "admin" page lists requests received and responses sent:
http://localhost:4567/admin

## Sources

The project contains these primary source files:
* app.rb: Specification of the HTTP service, including configuration (environments and API usernames and passwords) and HTTP routes and handlers.
* models.rb: Classes representing the constituent parts of an API request (Company, Owner) or response (Decision, Offer).  Request validation happens here.
* underwriting.rb: Toy logic for making a preapproval decision.

## Tests

This project has unit tests under ./test.  To run them:

    bundle exec ruby -Ilib:test test/app_test.rb

If you didn't install with bundler, "gem install" each gem listed in the Gemfile.

## Issues or Contributions

Reach out to your Fundera contact, post an issue at https://github.com/fundera/push-api-example, or tech - at - fundera.com.
