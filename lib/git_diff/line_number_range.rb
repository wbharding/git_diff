module GitDiff
  class LineNumberRange
    attr_reader :start, :number_of_lines

    # See range_info.rb for details about hunk unified diff format. It can be either a comma-separate pair of values
    # when more than one line is involved, or a single line when not
    def self.from_string(string)
      start_at, line_count = string.split(",")
      line_count ||= 1
      new(start_at, line_count)
    end

    def initialize(start = 0, number_of_lines = 0)
      @start = start.to_i
      @number_of_lines = number_of_lines.to_i
    end

    def to_s(type)
      "#{type}#{start},#{number_of_lines}"
    end
  end
end