lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nxnznv/version'

Gem::Specification.new do |gem|
  gem.name          = "nxnznv"
  gem.version       = Nxnznv::VERSION
  gem.authors       = ["Phil Hofmann"]
  gem.email         = ["phil@branch14.org"]
  gem.description   = %q{Ruby library and command line client to Akamai MCD REST API.}
  gem.summary       = %q{Ruby library and command line client to Akamai MCD REST API.}
  gem.homepage      = "https://github.com/branch14/nxnznv"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'nokogiri'
end
