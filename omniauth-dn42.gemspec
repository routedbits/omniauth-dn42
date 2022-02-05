# -*- encoding: utf-8 -*-
require File.expand_path('../lib/omniauth-dn42/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jonathan Voss"]
  gem.email         = ["jvoss@onvox.net"]
  gem.description   = %q{OmniAuth strategy for ASN ownership on the dn42regsrv}
  gem.summary       = %q{OmniAuth strategy based on the dn42 registry}
  gem.homepage      = "https://github.com/routedbits/omniauth-dn42"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "omniauth-dn42"
  gem.require_paths = ["lib"]
  gem.version       = OmniAuth::Dn42::VERSION

  gem.add_dependency 'omniauth', '~> 2.0'
  gem.add_dependency 'faraday'
  gem.add_dependency 'gpgme'
  gem.add_dependency 'multi_json'
end
