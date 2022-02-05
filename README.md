# OmniAuth DN42 Registry Strategy

This gem provides a simple authentication mechanism to validate the maintainer
of a given Autonomous System in DN42

## Installation

Add to your application's Gemfile:

```ruby
gem 'omniauth-dn42', git: 'https://github.com/routedbits/omniauth-dn42.git'
```

### Sinatra configuration

```ruby
require 'sinatra'
require 'omniauth'

class MyApplication < Sinatra::Base
  use Rack::Session::Cookie
  use OmniAuth::Strategies::Dn42
end
```

### Rails configuration

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer unless Rails.env.production?
  provider :dn42
end
```

## Development Getting Started

1) Clone the repo

2) Install the required gems

        bundle install

3) Install Sinatra

        gem install sinatra

3) Make changes

4) Use the example to verify

        ruby examples/sinatra.rb

## Authentication Flow

1) Request Phase (`request_phase`) [OmniAuth builtin]
   * Renders ASN Prompt
   * Sets Post to `method_path` (OmniAuth posts to `other_phase` method)

2) Other Phase (OmniAuth builtin)
   1) Method Phase
      * Receives form post from `request_phase`
      * Calls dn42regsrv for auth attributes of AS Maintaner object
      * Renders select form

   2) Challenge Phase
      * Receives post from `method_phase`
      * Renders challenge for user to sign
   
3) Callback Phase (OmniAuth builtin)
   * Validates challenge from `challenge_phase`
