#!/usr/bin/env ruby

require 'bundler/setup'
require 'dotenv/load'

require 'json'

require 'faraday'
require 'vcr'

WANIKANI_APIURL='https://api.wanikani.com/'
WANIKANI_APIREV='20170710'
WANIKANI_APIKEY=ENV["WANIKANI_APIKEY"]
WANIKANI_APILOG=false

if !WANIKANI_APIKEY
  $stderr.puts "WANIKANI_APIKEY required"
  Process.exit
end

def paginated_data(conn, url, &blk)
  return [] if !url
  resp = conn.get(url, &blk) 
  body = JSON.parse(resp.body)
  puts body["pages"].inspect
  return (body["data"] || []) + paginated_data(conn, body["pages"]["next_url"])
end

def subjects(conn)
  data = nil
  VCR.use_cassette("/v2/subjects") do
    data = paginated_data(conn, "/v2/subjects") { |req| req.params["types"] = "kanji,vocabulary" }
  end
  return data
end

VCR.configure do |c|
  c.default_cassette_options = { :serialize_with => :yaml,  :match_requests_on => [:method, :uri, :query], :record => :new_episodes }
  c.cassette_library_dir = 'cache/wanikani'
end

req_headers = {
    'Content-Type' => 'application/json',
    'Authorization' => "Bearer #{WANIKANI_APIKEY}",
    'Wanikani-Revision' => "#{WANIKANI_APIREV}"
  }
conn = Faraday.new(url: WANIKANI_APIURL, headers: req_headers) do |f|
  f.use Faraday::Response::Logger if WANIKANI_APILOG
  f.use VCR::Middleware::Faraday
end

# VCR.use_cassette("/v2/user") do
#   resp = conn.get("/v2/user") 
#   puts "response:"
#   userBody = JSON.parse(resp.body)
#   puts userBody
# end

subjects(conn).take(10).each do |sub|
  puts sub["data"]["characters"]
end