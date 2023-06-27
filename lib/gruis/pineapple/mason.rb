module Gruis
  module Pineapple
    class Mason

      attr_reader :wanikani

      def initialize(wanikani, log: false)
        @log = log
        @wanikani = wanikani
      end

      def log(msg = nil)
        return unless @log
        $stderr.puts msg if msg
        $stderr.puts yield if block_given?
      end

      # collision frequency
      def three
        # TODO: we probably want to take the X-kanji compounds that have the fewest similarities between them and other compounds
        #       we want to prioritize compounds that have kanji which are not in other compounds
        #comp_prior      = wanikani.kanji_vocab_compounds.sort_by { |v| 0 - v.length }
        
        # These compounds are composed of kanji that are not in any other compounds
        uniqs = wanikani.kanji_vocab_compounds.select do |vc| 
          wanikani.kanjis_for(vc).all? { |k| wanikani.kanji_comps_for(k).length == 1 }
        end
        puts "uniqs: #{uniqs.map(&:to_s)}"

        5.times.each do |cnt|
          col = wanikani.kanji_vocab_compounds.select do |vc| 
            wanikani.kanjis_for(vc).all? { |k| wanikani.kanji_comps_for(k).length == cnt + 1 }
          end

          col_map = col.map do |vc|
            [ 
              vc.to_s, 
              wanikani.kanjis_for(vc).map { |k| [k.to_s, wanikani.kanji_comps_for(k).map(&:to_s)] }
            ]
          end
          puts "#{cnt} collision: \n#{col_map.map { |k,c| "#{k}:#{c}"}.join("\n")}"
        end
      end

      # dup ratios in the study list
      def two
        # This algorithm should select comps with the lowest dup ratio; starts at 0
        # do we have to recalculate the dup ratio for all comps every time we add one to the study list?
        #    no just for the comps that have kanji found in the item added to the list
        #    so we'll need to be able to go from kanji to comp, not just comp to kanjis
        study_list      = []

        wanikani.kanji[1000...1010].map do |k|
          puts "#{k.to_s}: #{wanikani.kanji_comps_for(k).map(&:to_s)}"
        end
      end

      def one
        kanji_visits    = Hash[wanikani.kanji.map { |k| [k.to_s, false] }]
        study_list      = []
        comp_prior      = wanikani.kanji_vocab_compounds.sort_by { |v| 0 - v.length }
        all_kanji       = kanji_visits.keys
        kanji_visit_cnt = 0
        all_kanji_cnt   = all_kanji.length
        skip_cnt        = 0

        log do
          not_visited = kanji_visits.select { |k,v| !v }.keys
          visited = kanji_visits.select { |k,v| v }.keys

          "=========\n" +
          "  START\n" +
          "---------\n" +
          "all kanji cnt: #{all_kanji_cnt}; kanji visit cnt: #{kanji_visit_cnt}\n" +
          "all comp cnt: #{comp_prior.length}\n" +
          "visited:\n#{visited.inspect}\n#{visited.length}\n" +
          "not visited:\n#{not_visited.inspect}\n#{not_visited.length}\n" +
          "study list:\n#{study_list.inspect}\n#{study_list.length}\n" +
          "=========\n\n\n"
        end

        comp_prior.each do |c|
          break if kanji_visit_cnt == all_kanji_cnt
          kanjis = wanikani.kanjis_for(c)
          already_in_list = kanjis.select { |k| kanji_visits[k.to_s] }
          if already_in_list.empty?
            log "#{c}: #{kanjis.map(&:to_s)}" 
            study_list.push(c.to_s)
            kanjis.each { |k| kanji_visits[k.to_s] = true }
            kanji_visit_cnt = kanji_visit_cnt + kanjis.length
          else
            if already_in_list.length != kanjis.length
              log "skip '#{c}'; contains kanji already in the study list: #{already_in_list.map(&:to_s)}" 
              skip_cnt = skip_cnt + 1
            end
          end
        end

        log do
          visited = kanji_visits.select { |k,v| v }.keys
          not_visited = kanji_visits.select { |k,v| !v }.keys
          "=========\n" +
          "  END\n" +
          "---------\n" +
          "all kanji cnt: #{all_kanji_cnt}; kanji visit cnt: #{kanji_visit_cnt}\n" + 
          "all comp cnt: #{comp_prior.length}\n" +
          "skip cnt: #{skip_cnt}\n" +
          "visited:\n#{visited.inspect}\n#{visited.length}\n" + 
          "not visited:\n#{not_visited.inspect}\n#{not_visited.length}\n" + 
          "study list:\n#{study_list.inspect}\n#{study_list.length}\n" +
          "=========\n" 
        end
      end
    end
  end
end