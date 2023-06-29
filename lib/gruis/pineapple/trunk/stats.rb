module Gruis
  module Pineapple
    # Trunk holds all possible Subjects gathered from various sources, e.g., Wanikani
    class Trunk
      class Stats
        attr_reader :trunk
        def initialize(trunk)
          @trunk = trunk
        end

        # Recalculate the statistics
        # Call this method after you make changes to the trunk
        def reset!
          @kanji_freq = nil
          @compound_freq = nil
          self
        end

        def kanji_freqs
          @kanji_freq ||= kanji_freqs!
        end

        def kanji_freqs!
          freqs = Hash[trunk.kanji.map { |k| [k.to_s, 1] }]
          ttlcomps = (trunk.kanji_vocab_compounds.length).to_f
          freqs.keys.each do |k|
            comps = trunk.kanji_comps_for(k)
            if comps.length == 0
              freqs[k] = 0
            else
              ratio = (comps.length).to_f / ttlcomps
              freqs[k] = ratio
            end
          end
          freqs.sort_by {|k,v| v }.to_h
        end

        def compound_freq(*kanjis)
          kanjis = kanjis.map(&:to_s)
          cnt    = kanjis.length.to_f
          freqs  = kanjis.map { |k| kanji_freqs[k] || 0 }
          total  = freqs.reduce(&:+)
          freq   = total / cnt
        end

        def compound_freqs
          @compound_freq ||= compound_freqs!
        end

        def compound_freqs!
          kanji_freqs = kanji_freqs
          compounds = trunk.kanji_vocab_compounds.map do |c|
          [c.to_s, compound_freq(*trunk.kanjis_for(c))]
          end
          Hash[compounds.sort_by{ |f| f.last }]
        end
      end
    end
  end
end

