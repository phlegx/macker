# encoding: UTF-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'macker/version'

Gem::Specification.new do |spec|
  spec.name          = 'macker'
  spec.version       = Macker::VERSION
  spec.authors       = ['Egon Zemmer']
  spec.email         = ['office@phlegx.com']
  spec.date          = Time.now.utc.strftime('%Y-%m-%d')
  spec.homepage      = "https://github.com/phlegx/#{spec.name}"

  spec.summary       = 'Real MAC addresses maker.'
  spec.description   = 'Real MAC addresses generator and vendor lookup with MAC address handling.'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
                                        .reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.test_files    = Dir.glob('test/*_test.rb')
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 1.9.3'

  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rr', '~> 1.2'
  spec.add_development_dependency 'minitest', '~> 5.8'
  spec.add_development_dependency 'inch', '~>0.7.1'
end
