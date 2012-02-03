require 'tapunit'
Test::Unit::AutoRunner.default_runner = ENV['rpt'] || 'tapj'
Test::Unit.run = false
