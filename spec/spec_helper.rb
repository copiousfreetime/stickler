require 'spec'
require 'rack/test'

Spec::Runner.configure do |config|
  config.before(:each)  do
  end
  config.include Rack::Test::Methods
end


