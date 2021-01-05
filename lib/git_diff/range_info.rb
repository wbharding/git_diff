# ---------------------------------------------------------------------------
# Interpret range string from patch file, i.e., parse
# @@ -34,6 +34,8 @@
# ... into @original_range and @new_range instance vars, where for this example 6 lines have been extracted starting
# at line 34 and 8 lines have been added starting at line 34
#
# Info on how this should be done at https://stackoverflow.com/questions/10950412/what-does-1-1-mean-in-gits-diff-output
# Or http://www.gnu.org/software/diffutils/manual/diffutils.html#Detailed-Unified
# Atlassian has a concise explanation of the unified hunk format under "4. Diff chunks" at https://www.atlassian.com/git/tutorials/saving-changes/git-diff
#
# Per GNU,
#  "If a hunk and its context contain two or more lines, its line numbers look like ‘start,count’."
#  "Otherwise only its end line number appears. An empty hunk is considered to end at the line that precedes the hunk."
module GitDiff
  class RangeInfo
    attr_reader :original_range, :new_range, :header

    module ClassMethods
      def from_string(string)
        if(range_data = extract_hunk_range_data(string))
          new(*range_data.captures)
        end
      end

      # Example diff strings e.g., from https://github.com/alloy-org/ample-api/commit/b99d92b8d9474049c1cebf05731924c55c78cd89.diff
      # @@ -1,219 +1,80 @@
      # @@ -226,24 +87,10 @@ a {
      # @@ -1 +1 @@
      def extract_hunk_range_data(string)
        /^@@ \-([\d,]+) \+([\d,]+) @@(.*)/.match(string)
      end
    end

    extend ClassMethods

    # `original_range` and `new_range` are strings of the form
    # "73,8" # 8 lines starting at 73
    # "1" # A single line at line 1
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
