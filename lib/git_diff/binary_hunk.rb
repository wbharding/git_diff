require "forwardable"

module GitDiff
  class BinaryHunk < Hunk
    def initialize
      @lines = []
    end

    private

    def collector
      GitDiff::StatsCollector::BinaryHunk.new(self)
    end
  end
end
