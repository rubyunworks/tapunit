module Test
  module Unit
    AutoRunner.register_runner(:tapy) do |auto_runner|
      require 'tapunit/testrunner'
      TapUnit::TapY
    end
  end
end


