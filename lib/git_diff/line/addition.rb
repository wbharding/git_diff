module GitDiff
  module Line
    class Addition < Context
      def line_number=(line_number)
        @line_number = LineNumber.for_addition(line_number)
      end

      def addition?
        true
      end

      def context?
        false
      end
    end
  end
end