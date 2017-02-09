require "git_diff/line/context"
require "git_diff/line/addition"
require "git_diff/line/deletion"

module GitDiff
  module Line
    module ClassMethods
      def from_string(string)
        # Get rid of the + or - at the beginning of an addition/subtraction string.
        # That info is already communicated by the line's class.
        line_class(string[0]).new(string.gsub(/^[\-\+]/, ""))
      end

      def line_class(symbol)
        line_classes[symbol] || Context
      end

      def line_classes
        { "+" => Addition, "-" => Deletion }
      end
    end
    extend ClassMethods
  end
end
