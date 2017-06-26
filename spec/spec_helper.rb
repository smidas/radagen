$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rspec'
require 'radagen'

RSpec.configure do |config|
  config.tty = true

  config.before(:example) do
    @seed = ENV.fetch('PRNG_SEED', Random.new_seed).to_i
  end

  config.after(:example) do |spec|
    puts "PRNG_SEED: \e[38;5;208m#{@seed}\e[0m" if spec.exception
  end

  config.before(:example, :wip) do
    skip('Test marked as WIP')
  end

end