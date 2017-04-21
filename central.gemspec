# coding: utf-8
version = File.read('CENTRAL_VERSION').strip

Gem::Specification.new do |spec|
  spec.name          = "central"
  spec.version       = version
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

  spec.files         = ["README.md"]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency "central-core", version
  spec.add_dependency "central-rails", version
end
