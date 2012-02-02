module Test
  module Unit
    AutoRunner.register_runner(:tapj) do |auto_runner|
      require 'tapunit/testrunner'
      TapUnit::TapJ
    end
  end
end

