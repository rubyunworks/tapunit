begin
  gem 'test-unit'
rescue Exception 
end

require 'test/unit'

# prevent autorun
Test::Unit.run = true

# register the report formats
module Test #:nodoc:
  module Unit
    AutoRunner.register_runner(:tapy) do |auto_runner|
      require 'tapunit/testrunner'
      TapUnit::TapY
    end
    AutoRunner.register_runner(:tapj) do |auto_runner|
      require 'tapunit/testrunner'
      TapUnit::TapJ
    end
  end
end

