# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'journal/version'

Gem::Specification.new do |spec|
  spec.name          = 'journal'
  spec.version       = Journal::VERSION
  spec.authors       = ['Juan D Frias']
  spec.email         = ['juandfrias@gmail.com']

  spec.summary       = 'Yet another ruby logger class'
  spec.homepage      = 'https://github.com/hawkprime/ruby-journal'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
end
