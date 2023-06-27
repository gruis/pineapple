#!/usr/bin/env ruby

require 'bundler/setup'
require 'dotenv/load'

require 'gruis/pineapple/wanikani'


WANIKANI_APIKEY=ENV["WANIKANI_APIKEY"]
if !WANIKANI_APIKEY
  $stderr.puts "WANIKANI_APIKEY required"
  Process.exit
end


cache    = File.expand_path("../../cache/wanikani", __FILE__)
log      = false
wanikani = Gruis::Pineapple::Wanikani.new(WANIKANI_APIKEY, log: log, cache: cache)

# wanikani.kanji.take(10).each do |sub|
#   puts sub
# end
# 
# wanikani.kanji_vocab_compounds.sort_by { |v| 0 - v.length }.take(50).each do |sub|
#   puts sub
# end
# 
# puts wanikani.subject_by_id(520).to_h
kanji_visits = Hash[wanikani.kanji.map { |k| [k.to_s, false] }]
study_list  = []
comp_prior  = wanikani.kanji_vocab_compounds.sort_by { |v| 0 - v.length }
all_kanji = kanji_visits.keys
kanji_visit_cnt = 0
all_kanji_cnt = all_kanji.length
skip_cnt = 0

if log
  puts "========="
  puts "  START"
  puts "---------"
  puts "all kanji cnt: #{all_kanji_cnt}; kanji visit cnt: #{kanji_visit_cnt}"
  puts "all comp cnt: #{comp_prior.length}"
  not_visited = kanji_visits.select { |k,v| !v }.keys
  visited = kanji_visits.select { |k,v| v }.keys
  puts "visited:\n#{visited.inspect}\n#{visited.length}"
  puts "not visited:\n#{not_visited.inspect}\n#{not_visited.length}"
  puts "study list:\n#{study_list.inspect}\n#{study_list.length}"
  puts "=========\n\n\n"
end

# TODO: change the algorithm to select comps with the lowest dup ratio; starts at 0
# do we have to recalculate the dup ratio for all comps every time we add one to the study list?
#    no just for the comps that have kanji found in the item added to the list
#    so we'll need to be able to go from kanji to comp, not just comp to kanjis

comp_prior.each do |c|
  break if kanji_visit_cnt == all_kanji_cnt
  kanjis = wanikani.kanjis_for(c)
  already_in_list = kanjis.select { |k| kanji_visits[k.to_s] }
  if already_in_list.empty?
    $stderr.puts "#{c}: #{kanjis.map(&:to_s)}" if log
    study_list.push(c.to_s)
    kanjis.each { |k| kanji_visits[k.to_s] = true }
    kanji_visit_cnt = kanji_visit_cnt + kanjis.length
  else
    if already_in_list.length != kanjis.length
      $stderr.puts "skip '#{c}'; contains kanji already in the study list: #{already_in_list.map(&:to_s)}" if log
      skip_cnt = skip_cnt + 1
    end
  end
end

puts "========="
puts "  END"
puts "---------"
puts "all kanji cnt: #{all_kanji_cnt}; kanji visit cnt: #{kanji_visit_cnt}"
puts "all comp cnt: #{comp_prior.length}"
puts "skip cnt: #{skip_cnt}"
visited = kanji_visits.select { |k,v| v }.keys
not_visited = kanji_visits.select { |k,v| !v }.keys
puts "visited:\n#{visited.inspect}\n#{visited.length}"
puts "not visited:\n#{not_visited.inspect}\n#{not_visited.length}"
puts "study list:\n#{study_list.inspect}\n#{study_list.length}"
puts "========="
