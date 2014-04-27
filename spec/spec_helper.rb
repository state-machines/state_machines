require 'state_machines'
require 'stringio'
Dir['./spec/support/**/*.rb'].sort.each { |f| require f }
RSpec.configure do |config|
  config.raise_errors_for_deprecations!
end
