# Central::Rails
Short description and motivation.

## Usage

You need to declare :

```ruby
module SomeApp
  class Application < Rails::Application
    config.central_check = lambda do |request|
      # do something with request ...
    end
  end
end

```

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'central-rails'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install central-rails
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
