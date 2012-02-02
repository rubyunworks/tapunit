require 'tapunit'

Test::Unit::AutoRunner.default_runner = ENV['rpt'] || 'tapy'
Test::Unit.run = true

