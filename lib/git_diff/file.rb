      elsif(/^Binary files a?\/(.*) and b?\/(.*) differ$/ === string)
        add_hunk BinaryHunk.new
    def binary?
      hunks.all? do |hunk|
        BinaryHunk === hunk
      end
    end

      when a_path_info = /^[-]{3} a?\/(.*)$/.match(string)
      when b_path_info = /^[+]{3} b?\/(.*)$/.match(string)