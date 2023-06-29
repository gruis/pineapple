#!/usr/bin/env ruby
require 'bundler/setup'
require 'dotenv/load'
require 'pry'

require 'gruis/pineapple/wanikani'
require 'gruis/pineapple/trunk'
require 'gruis/pineapple/trunk/stats'
require 'gruis/pineapple/mason'


WANIKANI_APIKEY=ENV["WANIKANI_APIKEY"]
if !WANIKANI_APIKEY
  $stderr.puts "WANIKANI_APIKEY required"
  Process.exit
end


cache    = File.expand_path("../../cache/wanikani", __FILE__)
log      = false
wanikani = Gruis::Pineapple::Wanikani.new(WANIKANI_APIKEY, log: log, cache: cache, types: "kanji,vocabulary,radical")
trunk    = Gruis::Pineapple::Trunk.new(wanikani.subjects)
stats    = trunk.stats
mason    = Gruis::Pineapple::Mason.new(trunk, log: false)

binding.pry
