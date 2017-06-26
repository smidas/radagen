$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rspec'
require 'radagen'

RSpec.configure do |config|
  config.tty = true

  config.before(:example, :wip) do
    skip('Test marked as WIP')
  end
end