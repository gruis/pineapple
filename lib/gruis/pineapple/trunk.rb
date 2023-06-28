module Gruis
  module Pineapple
    # Trunk holds all possible Subjects gathered from various sources, e.g., Wanikani
    class Trunk

      def initialize(subjects)
        # text indexed
        @subjects = OpenStruct.new({kanji: {}, radical: {}, vocabulary: {}})
        reset!
        add(*subjects)
      end

      def [](text)
        @subjects[text]
      end

      def add(*subs)
        subs.each do |sub|
          @subjects[sub.type][sub.to_s] = sub unless @subjects[sub.type][sub.to_s]
        end
        index!
      end

      def radicals
        @radicals ||= @subjects.radical.values
      end

      def kanji
        @kanji ||= @subjects.kanji.values
      end

      def vocab
        @vocab ||= @subjects.vocabulary.values
      end

      def kanji_vocab
        @kanji_vocab ||= vocab.select(&:is_only_kanji?) 
      end

      def kanji_vocab_compounds
        @kanji_vocab_compounds ||= kanji_vocab
          .select(&:is_compound?)
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

      def subject_by_id(id)
        @id_index[id]
      end

      def subjects
        radicals + kanji + vocab
      end

      private

      def reset!
        @id_index    = {}
        @comp_index  = {}
        @vocab_index = {}
        @kanji_comp_by_kanji = Hash.new { |h,k| h[k] = {} }
        @comp_by_kanji = Hash.new { |h,k| h[k] = {} }
      end

      def index!
        reset!
        subjects.each { |s| @id_index[s.id] = s }
        vocab.each do |s|
          kanjis_for(s).each {|k| @comp_by_kanji[k.to_s][s.to_s] = s }
          if s.is_compound?
            kanjis_for(s).each {|k| @kanji_comp_by_kanji[k.to_s][s.to_s] = s }
          end
        end
        subjects
      end
    end
  end
end