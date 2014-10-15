module GitDiff
  module StatsCollector
    class BinaryHunk < Hunk
      def collect
        GitDiff::Stats.new(
          number_of_lines: 0,
          number_of_additions: 0,
          number_of_deletions: 0
        )
      end
    end
  end
end
