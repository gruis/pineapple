#!/usr/bin/env ruby

require 'bundler/setup'
require 'dotenv/load'

require 'gruis/pineapple/wanikani'
require 'gruis/pineapple/mason'


WANIKANI_APIKEY=ENV["WANIKANI_APIKEY"]
if !WANIKANI_APIKEY
  $stderr.puts "WANIKANI_APIKEY required"
  Process.exit
end


cache    = File.expand_path("../../cache/wanikani", __FILE__)
log      = false
wanikani = Gruis::Pineapple::Wanikani.new(WANIKANI_APIKEY, log: log, cache: cache)

Gruis::Pineapple::Mason.new(wanikani, log: true).three