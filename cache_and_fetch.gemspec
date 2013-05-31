# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cache_and_fetch/version'

Gem::Specification.new do |spec|
  spec.name          = "cache_and_fetch"
  spec.version       = CacheAndFetch::VERSION
  spec.authors       = ["Suman Mukherjee"]
  spec.email         = ["sumanmukherjee03@gmail.com"]
  spec.description   = %q{A gem that allows you to soft expire cache, use a stale resource and fetch the fresh resource in background}
  spec.summary       = %q{This gem allows you to add a soft expiry to your cache. When the cache soft expires, the cache provides you the stale record to work with, but fetches the fresh record in the background.}
  spec.homepage      = "http://github.com/sumanmukherjee03/cache_and_fetch"
  spec.license       = "MIT"

  spec.files         = Dir['lib/**/*.rb']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rails"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
