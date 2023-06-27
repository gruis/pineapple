require 'json'
require 'faraday'
require 'vcr'
require 'gruis/pineapple/wanikani/subject'


module Gruis
  module Pineapple
    # Wanikani API interface. It includes a caching layer in order to play nice
    # with the Wanikani terms of use. 
    class Wanikani
      WANIKANI_APIURL='https://api.wanikani.com/'
      WANIKANI_APIREV='20170710'

      attr_reader :id_index

      def initialize(apikey, log: false, url: WANIKANI_APIURL, rev: WANIKANI_APIREV, cache: false, subjects: "kanji,vocabulary")
        @apikey   = apikey
        @log      = log
        @apiurl   = url
        @apirev   = rev
        @cache    = cache
        @memos    = {}
        @subjects = subjects

        @id_index    = {}
        @kanji_index = {}
        @comp_index  = {}
        @vocab_index = {}
        @kanji_comp_by_kanji = Hash.new { |h,k| h[k] = {} }
        @comp_by_kanji = Hash.new { |h,k| h[k] = {} }
        config_cache! if cache
      end

      def kanji
        @kanji ||= subjects.select(&:kanji?)
      end

      def kanji_vocab
        @kanji_vocab ||= vocab.select(&:is_only_kanji?) 
      end

      def kanji_vocab_compounds
        @kanji_vocab_compounds ||= kanji_vocab
          .select(&:is_compound?)
      end

      def vocab
        @vocab ||= subjects.select(&:vocabulary?)
      end

      def kanjis_for(subject)
        subject.component_subject_ids.map { |sid| subject_by_id(sid) }
      end

      # Find all vocabulary compounds which contain the given kanji
      def comps_for(kanji_subject)
        @comp_by_kanji[kanji_subject.to_s].values
      end

      # Find all kanji-only vocabulary compounds which contain the given kanji
      def kanji_comps_for(kanji_subject)
        @kanji_comp_by_kanji[kanji_subject.to_s].values
      end

      def subjects(types = @subjects)
        memoize(types) do 
          cache("/v2/subjects") do
            index!(
              paginated_data("/v2/subjects") { |req| req.params["types"] = types }
                .map{|s| Subject.new(s) }
            )
          end
        end
      end

      def index!(subs)
        subs.each do |s| 
          @id_index[s.id] = s 
          if s.kanji?
            @kanji_index[s.to_s] = s
          end
        end
        subs.each do |s|
          if s.vocabulary?
            kanjis_for(s).each {|k| @comp_by_kanji[k.to_s][s.to_s] = s }
            if s.is_compound?
              kanjis_for(s).each {|k| @kanji_comp_by_kanji[k.to_s][s.to_s] = s }
            end
          end
        end
        subs
      end

      def subject_by_id(id)
        @id_index[id]
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