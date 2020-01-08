module GitDiff
  class File
    DEV_NULL = "dev/null"

    attr_reader :a_path, :a_blob, :a_mode, :b_path, :b_blob, :b_mode, :header, :hunks, :similarity_index

    def self.from_string(string)
      if /^diff --git/.match(string)
        File.new(string)
      elsif /^diff -r [a-f0-9]+ -r [a-f 0-9]+/.match(string)
        # Alternative format for diff header
        File.new(string)
      end
    end

    def initialize(header)
      @header = header
      @hunks = []
      @renamed = false

      get_paths_from_header
    end

    def <<(string)
      return if extract_diff_meta_data(string)

      if(range_info = RangeInfo.from_string(string))
        add_hunk Hunk.new(range_info)
      elsif(path_info = /^Binary files a?\/(.*) and b?\/(.*) differ$/.match(string))
        @a_path = path_info[1]
        @b_path = path_info[2]

        add_hunk BinaryHunk.new
      elsif(path_info = /^Binary file (.*) has changed$/.match(string))
        @a_path = path_info[1]
        @b_path = path_info[2]

        add_hunk BinaryHunk.new
      elsif current_hunk.nil? && (string.starts_with?("+++") || string.ends_with?("---"))
        # All the info implied by these +++ and --- bits preceding a hunk is implied by the a and b paths - skip
      else
        append_to_current_hunk string
      end
    end

    def each_hunk
      hunks.to_enum(:each)
    end

    def stats
      @stats ||= Stats.total(collector)
    end

    def binary?
      !hunks.empty? && hunks.all? { |hunk| BinaryHunk === hunk }
    end

    def new_file?
      a_path == DEV_NULL
    end

    def deleted_file?
      b_path == DEV_NULL
    end

    def mode_changed?
      a_mode && b_mode && a_mode != b_mode
    end

    def renamed?
      @renamed
    end

    private

    attr_accessor :current_hunk

    def collector
      GitDiff::StatsCollector::Rollup.new(hunks)
    end

    def add_hunk(hunk)
      self.current_hunk = hunk
      hunks << current_hunk
    end

    def append_to_current_hunk(string)
      # WBH Dec 2019 observes that there are cases like https://github.com/vuejs/vue/commit/585c97cd6a55840ea4c7925a066c1cd9d6d51daa
      # where binary files are interpreted as having a string but no hunks to add those strings to. We'll ignore such files.
      if current_hunk
        current_hunk << string
      else
        nil
      end
    end

    # Initialize the paths from the header. These may be changed by extract_diff_meta_data.
    def get_paths_from_header
      # We have two main formats for headers: src:// and dst://, vs. a/ and b/. Let's standardize to the latter.
      standardized_path_headers = header.sub("src://", "a/").sub("dst://", "b/")
      path_info = /^diff --git ((\")?a?\/(.*)) ((\")?b?\/(.*))$/.match(standardized_path_headers)
      if path_info
        @a_path = path_info[1]
        @b_path = path_info[4]

        # Sometimes the patch components have  quotes around them. e.g: \"a/some/file\"
        @a_path = @a_path[1..-2] if @a_path.starts_with?("\"") && @a_path.ends_with?("\"")
        @b_path = @b_path[1..-2] if @b_path.starts_with?("\"") && @b_path.ends_with?("\"")

        # And they almost always have an a/ and b/ at the beginning
        @a_path = @a_path[2..-1] if @a_path.starts_with?("a/")
        @b_path = @b_path[2..-1] if @b_path.starts_with?("b/")
      else
        # Alternative format for diff headers
        path_info = /^diff -r ([a-f0-9]*) -r ([a-f0-9]*) (.*)$/.match(standardized_path_headers)
        @a_path = path_info[3]
        @b_path = path_info[3]
      end
    end

    def extract_diff_meta_data(string)
      case
      when a_path_info = /^[-]{3} a?\/(.*)$/.match(string)
        @a_path = a_path_info[1]
      when b_path_info = /^[+]{3} b?\/(.*)$/.match(string)
        @b_path = b_path_info[1]
      when blob_info = /^index ([0-9A-Fa-f]+)\.\.([0-9A-Fa-f]+) ?(.+)?$/.match(string)
        @a_blob, @b_blob, @b_mode = *blob_info.captures
      when /^new file mode [0-9]{6}$/.match(string)
        @a_path = DEV_NULL
      when /^deleted file mode [0-9]{6}$/.match(string)
        @b_path = DEV_NULL
      when similarity_index_info = /^similarity index (\d+)/.match(string)
        @similarity_index = similarity_index_info[1].to_f / 100
      when /^rename (from|to) (.*)$/.match(string)
        @renamed = true
      when mode_info = /^(new|old) mode (\d+)/.match(string)
        if mode_info[1] == "old"
          @a_mode = mode_info[2]
        else
          @b_mode = mode_info[2]
        end
      # Ignore the "no newline" directive from patch file, as opposed to interpreting
      # it as a context line that spans before and after files in weird ways
      when /^. no newline at end of file/i.match(string)
        true
      end
    end
  end
end
