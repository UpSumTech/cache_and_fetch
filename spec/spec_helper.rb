$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require "rails"
require "active_resource"
require "webmock/rspec"
require "cache_and_fetch"
require "coveralls"

module CacheAndFetch
  class Application < ::Rails::Application
  end
end

CacheAndFetch::Application.initialize!

RSpec.configure do |config|
  config.before do
    Rails.cache.clear
  end

  config.mock_with :rspec
  config.order = 'random'
  config.color_enabled = true
  config.tty = true
end

Coveralls.wear!
