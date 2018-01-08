# ---------------------------------------------------------------------------
# Interpret range string from patch file, i.e., parse
# @@ -1,15 +0,0 @@
# ... into @original_range and @new_range instance vars
#
# Info on how this should be done at https://stackoverflow.com/questions/10950412/what-does-1-1-mean-in-gits-diff-output
# Or http://www.gnu.org/software/diffutils/manual/diffutils.html#Detailed-Unified
module GitDiff
  class RangeInfo
    attr_reader :original_range, :new_range, :header

    module ClassMethods
      def from_string(string)
        if(range_data = extract_hunk_range_data(string))
          new(*range_data.captures)
        end
      end

      def extract_hunk_range_data(string)
        /^@@ \-([\d,]+) \+([\d,]+) @@(.*)/.match(string)
      end
    end

    extend ClassMethods

    def initialize(original_range, new_range, header)
      @original_range = LineNumberRange.from_string(original_range)
      @new_range = LineNumberRange.from_string(new_range)
      @header = header.strip
    end

    def to_s
      "@@ #{original_range.to_s(:-)} #{new_range.to_s(:+)} @@ #{header}".strip
    end
  end
end
