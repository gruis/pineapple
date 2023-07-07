module Gruis
  module Pineapple
    class Mason

      attr_reader :trunk

      # primary goal: make a word list that contains all available kanji with 
      #               no repeats
      # fall back goal: make a word list that contains all available kanji 
      #                 with as few repeats as possible
      # secondary goal: determine if it is possible to make a word list that
      #                 contains all available kanji with no repeats

      # alternative strategy: build all possible word lists

      def initialize(trunk, log: false)
        @log   = log
        @trunk = trunk
      end

      def log(msg = nil)
        return unless @log
        $stderr.puts msg if msg
        $stderr.puts yield if block_given?
      end

      def suggestions(subject, source = trunk)
        source.kanji_comps_for(subject).map(&:to_s) 
          .map do |c| 
            [
              c, 
              # average frequency for each kanji in the compound
              source.stats.compound_freqs[c], 
              # average frequency for each kanji except the target kanji
              source.stats.compound_freq(*c.each_char.reject { |k| k == subject.to_s })
            ] 
          end
          .sort_by { |cf| cf.last }
      end

      def suggestions_one(*subjects)
        subjects.map { |s| trunk.kanji_comps_for(s).map(&:to_s) }
          .reduce {|a,b| a & b }
      end

      # summarize the results of a mason builder run - good for quickly
      # comparing efficiency of each algorithm
      def summarize
        data = yield
        data.map {|k,v| 
          [
            k, 
            {
              cnt: v.respond_to?(:length) && v.length,
              #kanji: v.keys.join(""),
              kanji_cnt: v.keys.join("").length,
              #kanji_uniq: v.keys.join("").each_char.uniq.join(""),
              kanji_uniq_cnt: v.keys.join("").each_char.uniq.length,
            }
          ] 
        }
      end


      # adaptive frequency
      def five
        kanji_unused = {}
        kanji_used   = {}
        study_list   = {}

        kanji_list   = trunk.stats.kanji_freqs.drop_while do |k,f| 
          # any compound with a frequency of 0 are not used in a compound, so
          # skip them, but keep a record
          if f == 0 
            kanji_unused[k] = f 
            true
          end
        end

        # for each kanji
        # calculate word frequency
        # take a word that is made entirely of unseen kanji
        # add all kanji in the word to the list of seen kanji
        # repeat until we've gone through all kannji
      end

      # kanji frequency
      def four
        kanji_unused = {}
        kanji_used   = {}
        study_list   = {}

        kanji_list   = trunk.stats.kanji_freqs.drop_while do |k,f| 
          # any compound with a frequency of 0 are not used in a compound, so
          # skip them, but keep a record
          if f == 0 
            kanji_unused[k] = f 
            true
          end
        end

        kanji_list.each do |k, f|
          # sort the suggested compounds by the frequency of the kanji in the
          # compound that are not `k`, from lowest to highest. we are
          # prioritizing the compounds that contain kanji, which are used in the
          # fewest other compounds
          #
          # then find the first compound made up entirely of kanji that are not
          # already in our study list
          comp = suggestions(k).sort_by { |cf| cf.last }
            .find { |cf| cf[0].each_char.none? { |k| kanji_used[k] } }
          if comp
            study_list[comp[0]] = comp[1] # record the composite frequency for the compound
            comp[0].each_char { |k| kanji_used[k] = trunk.stats.kanji_freqs[k] }
          end
        end
        kanji_list.each { |k,f| kanji_unused[k] = f unless kanji_used[k] }
        {
          study_list: study_list,
          kanji_used: kanji_used,
          kanji_unused: kanji_unused,
        }
      end

      # collision frequency
      def three
        # TODO: we probably want to take the X-kanji compounds that have the fewest similarities between them and other compounds
        #       we want to prioritize compounds that have kanji which are not in other compounds
        #comp_prior      = trunk.kanji_vocab_compounds.sort_by { |v| 0 - v.length }
        
        # These compounds are composed of kanji that are not in any other compounds
        uniqs = trunk.kanji_vocab_compounds.select do |vc| 
          trunk.kanjis_for(vc).all? { |k| trunk.kanji_comps_for(k).length == 1 }
        end
        puts "uniqs: #{uniqs.map(&:to_s)}"

        5.times.each do |cnt|
          col = trunk.kanji_vocab_compounds.select do |vc| 
            trunk.kanjis_for(vc).all? { |k| trunk.kanji_comps_for(k).length == cnt + 1 }
          end

          col_map = col.map do |vc|
            [ 
              vc.to_s, 
              trunk.kanjis_for(vc).map { |k| [k.to_s, trunk.kanji_comps_for(k).map(&:to_s)] }
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

        trunk.kanji[1000...1010].map do |k|
          puts "#{k.to_s}: #{trunk.kanji_comps_for(k).map(&:to_s)}"
        end
      end

      def one
        kanji_visits    = Hash[trunk.kanji.map { |k| [k.to_s, false] }]
        study_list      = []
        comp_prior      = trunk.kanji_vocab_compounds.sort_by { |v| 0 - v.length }
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
          kanjis = trunk.kanjis_for(c)
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

        visited     = Hash[kanji_visits.select { |k,v| v }.keys.map {|k| [k, trunk.stats.kanji_freqs[k]] }]
        not_visited = Hash[kanji_visits.select { |k,v| !v }.keys.map { |k| [k, trunk.stats.kanji_freqs[k]] }]
        study_list  = Hash[study_list.map { |c| [c, trunk.stats.compound_freqs[c] ]}]
        log do
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
        {
          study_list: study_list,
          kanji_used: visited,
          kanji_unused: not_visited,
        }
      end
    end
  end
end