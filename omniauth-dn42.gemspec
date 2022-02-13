# frozen_string_literal: true

require File.expand_path('lib/omniauth-dn42/version', __dir__)

Gem::Specification.new do |gem|
  gem.required_ruby_version = '>=2.6.9'
  gem.authors       = ['Jonathan Voss']
  gem.email         = ['jvoss@onvox.net']
  gem.description   = 'OmniAuth strategy for ASN ownership on the dn42regsrv'
  gem.summary       = 'OmniAuth strategy based on the dn42 registry'
  gem.homepage      = 'https://github.com/routedbits/omniauth-dn42'

  gem.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = 'omniauth-dn42'
  gem.require_paths = ['lib']
  gem.version       = OmniAuth::Dn42::VERSION

  gem.add_dependency 'faraday'
  gem.add_dependency 'gpgme'
  gem.add_dependency 'multi_json'
  gem.add_dependency 'omniauth', '~> 2.0'

  gem.metadata['rubygems_mfa_required'] = 'true'
end
