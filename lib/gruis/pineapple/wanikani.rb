require 'json'
require 'faraday'
require 'vcr'
require 'gruis/pineapple/subject'


module Gruis
  module Pineapple
    # Wanikani API interface. It includes a caching layer in order to play nice
    # with the Wanikani terms of use. 
    class Wanikani
      WANIKANI_APIURL='https://api.wanikani.com/'
      WANIKANI_APIREV='20170710'

      attr_reader :id_index

      def initialize(apikey, log: false, url: WANIKANI_APIURL, rev: WANIKANI_APIREV, cache: false, types: "kanji,vocabulary")
        @apikey   = apikey
        @log      = log
        @apiurl   = url
        @apirev   = rev
        @cache    = cache
        @memos    = {}
        @def_types    = types

       config_cache! if cache
      end

      def subjects(types = @def_types)
        memoize(types) do 
          cache("/v2/subjects") do
              paginated_data("/v2/subjects") { |req| req.params["types"] = types }
                .map{|s| Subject.new(s) }
          end
        end
      end

      private 

      def memoize(key, &blk)
        @memos[key] ||= yield
      end


      def cache(name, &blk)
        return yield unless @cache
        VCR.use_cassette(name, &blk)
      end

      def config_cache!
        VCR.configure do |c|
          c.default_cassette_options = { 
            :serialize_with => :yaml,  
            :match_requests_on => [:method, :uri, :query], 
            :record => :new_episodes 
          }
          c.cassette_library_dir = @cache
        end
      end

      def conn
        @con ||= Faraday.new(url: @apiurl, headers: req_headers) do |f|
          f.use Faraday::Response::Logger if @log
          f.use VCR::Middleware::Faraday if @cache
        end
      end

      def req_headers
        @req_headers ||= {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{@apikey}",
          'Wanikani-Revision' => "#{@apirev}"
        }
      end

      def paginated_data(url, &blk)
        return [] if !url
        body = JSON.parse(conn.get(url, &blk).body)
        $stderr.puts body["pages"].inspect if @log
        return (body["data"] || []) + paginated_data(body["pages"]["next_url"])
      end
    end
  end
end