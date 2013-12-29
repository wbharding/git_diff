module GitDiff
  module Line
    class Addition < Context
      extend GitDiff::Line::Change

      def self.change?(string)
        string.start_with?("+")
      end

      def initialize(content, line_number)
        super(content, line_number)
        @line_number = LineNumber.for_addition(line_number)
      end

      def addition?
        true
      end
    end
  end
end