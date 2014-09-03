# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hifsm/version'

Gem::Specification.new do |spec|
  spec.name          = "hifsm"
  spec.version       = Hifsm::VERSION
  spec.authors       = ["Vladimir Meremyanin"]
  spec.email         = ["vladimir@meremyanin.com"]
  spec.description   = %q{FSM with support for nested states and parameterised events}
  spec.summary       = %q{Hierarchical state machines in Ruby}
  spec.homepage      = "http://github.com/stiff/hifsm"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "sqlite3"
end
