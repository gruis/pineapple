require 'gruis/pineapple/trunk/stats'
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

      def stats
        @stats ||= Stats.new(self)
      end

      def [](text)
        @subjects.kanji[text] || @subjects.vocabulary[text]
      end

      def add(*subs)
        subs.each do |sub|
          @subjects[sub.type][sub.to_s] = sub unless @subjects[sub.type][sub.to_s]
        end
        index!
      end

      def del(sub)
        @subjects[sub.type].delete(sub.to_s)

        @id_index.delete(sub.id) if sub.id

        if sub.radical?
          @radicals.delete_if { |r| r.to_s == sub.to_s}
        elsif sub.kanji?
          @kanji.delete_if { |k| k.to_s == sub.to_s}
        elsif sub.vocabulary?
          @vocab.delete_if { |v| v.to_s == sub.to_s}
          @kanji_vocab.delete_if { |v| v.to_s == sub.to_s} if sub.is_only_kanji?
          @kanji_vocab_compounds.delete_if { |v| v.to_s == sub.to_s} if sub.is_compound?
        end
        stats.reset!
        sub
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
        sub = subject.is_a?(String) ? @subjects.vocabulary[subject] : subject
        raise ArgumentError.new("unknown subject #{subject}") unless sub
        sub.component_subject_ids.map { |sid| subject_by_id(sid) }
      end

      # Find all vocabulary compounds which contain the given kanji
      def comps_for(kanji_subject)
        sub = kanji_subject.is_a?(String) ? @subjects.kanji[kanji_subject] : kanji_subject
        raise ArgumentError.new("unknown kanji subject #{subject}") unless sub
        @comp_by_kanji[sub.to_s].values
      end

      # Find all kanji-only vocabulary compounds which contain the given kanji
      def kanji_comps_for(kanji_subject)
        sub = kanji_subject.is_a?(String) ? @subjects.kanji[kanji_subject] : kanji_subject
        raise ArgumentError.new("unknown kanji subject #{subject}") unless sub

        @kanji_comp_by_kanji[sub.to_s].values
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