require 'ostruct'
module Gruis
  module Pineapple
    # Subject is a study item. The structure is take 1:1 from Wanikani subject
    class Subject < OpenStruct
      def initialize(api_sub)
        super(api_sub["data"])
        self["id"]      = api_sub["id"]
        self["api_url"] = api_sub["url"]
        self["type"]    = api_sub["object"]
      end

      def kanji?
        self["type"] == "kanji"
      end

      def vocabulary?
        self["type"] == "vocabulary"
      end

      def radical?
        self["type"] == "radical"
      end

      def is_only_kanji?
        !(self.characters =~ /(\p{Katakana})|(\p{Hiragana})|〜|[0-9]|[０-９]/)
      end

      def is_compound?
        is_only_kanji? && length >= 2
      end

      def length
        self.characters.length
      end

      def to_s
        self.characters
      end
    end
  end
end
