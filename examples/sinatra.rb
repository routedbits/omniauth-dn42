# frozen_string_literal: true

$LOAD_PATH.push "#{File.dirname(__FILE__)}/../lib"

require 'omniauth-dn42'
require 'sinatra'

set sessions: true
use OmniAuth::Strategies::Dn42

get '/' do
  <<~HTML
    <form method='post' action='/auth/dn42'>
      <input type="hidden" name="authenticity_token" value='#{request.env['rack.session']['csrf']}'>
      <button type='submit'>Login with DN42</button>
    </form>
  HTML
end

post '/auth/dn42/callback' do
  content_type 'text/plain'
  request.env['omniauth.auth'].inspect
end

get '/auth/failure' do
  <<~HTML
    <div>You reached this due to an error in OmniAuth</div>
    <div>Strategy: #{params['strategy']}</div>
    <div>Message: #{params['message']}</div>
  HTML
end
