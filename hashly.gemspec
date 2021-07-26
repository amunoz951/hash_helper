# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = 'hashly'
  spec.version       = '0.2.0'
  spec.authors       = ['Alex Munoz']
  spec.email         = ['amunoz951@gmail.com']
  spec.license       = 'Apache-2.0'
  spec.summary       = 'Ruby library for ease of merging nested hashes recursively, diffing hashes, etc.'
  spec.homepage      = 'https://github.com/amunoz951/hashly'

  spec.required_ruby_version = '>= 2.3'

  spec.files         = Dir['LICENSE', 'lib/**/*']
  spec.require_paths = ['lib']
end
