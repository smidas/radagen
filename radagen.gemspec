# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'radagen/version'

Gem::Specification.new do |spec|
  spec.name          = "radagen"
  spec.version       = Radagen::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ["Nathan Smith"]
  spec.email         = ["n.m.smith2480@gmail.com"]
  spec.license       = "MIT"

  spec.summary       = "radagen - #{Radagen::VERSION}"
  spec.description   = 'Composable pseudo random data generator.'
  spec.homepage      = "https://github.com/smidas/radagen"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.5"
  spec.add_development_dependency "pry", "~> 0.10.4"
end
