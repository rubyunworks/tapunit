begin
  gem 'test-unit'
rescue Exception 
end

require 'test/unit'

require 'tapunit/tapy'
require 'tapunit/tapj'

Test::Unit.run = false
