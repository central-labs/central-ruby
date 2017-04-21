# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'central/version'

Gem::Specification.new do |spec|
  spec.name          = "central-core"
  spec.version       = Central::VERSION
  spec.authors       = ["Yuri Setiantoko"]
  spec.email         = ["yuri@bukalapak.com"]

  spec.summary       = %q{Centralized async settings using Redis}
  spec.description   = %q{Centralized distributed async settings using Redis PubSub}
  spec.homepage      = "https://gitlab.bukalapak.io/yuri/central"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://gitlab.bukalapak.io/yuri/central"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "redis"
  spec.add_development_dependency "connection_pool"
  spec.add_development_dependency "concurrent-ruby-edge"
  spec.add_development_dependency "diplomat"
end
