module GitDiff
  class File
    DEV_NULL = "dev/null"

    attr_reader :a_path, :a_blob, :b_path, :b_blob, :b_mode, :hunks, :similarity_index

    def self.from_string(string)
      if /^diff --git/.match(string)
        File.new
      end
    end

    def initialize
      @hunks = []
      @renamed = false
    end

    def <<(string)
      return if extract_diff_meta_data(string)

      if(range_info = RangeInfo.from_string(string))
        add_hunk Hunk.new(range_info)
      elsif(path_info = /^Binary files a?\/(.*) and b?\/(.*) differ$/.match(string))
        @a_path = path_info[1]
        @b_path = path_info[2]

        add_hunk BinaryHunk.new
      else
        append_to_current_hunk string
      end
    end

    def each_hunk
      @hunks.to_enum(:each)
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
      current_hunk << string
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
      when renamed_path_info = /^rename (from|to) (.*)$/.match(string)
        @renamed = true
        if renamed_path_info[1] == "from"
          @a_path = renamed_path_info[2]
        else
          @b_path = renamed_path_info[2]
        end
      end
    end
  end
end
