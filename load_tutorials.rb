# Copyright 2016 Trimble Navigation Limited
# Licensed under the MIT license

module Examples

  # Finds and returns the filename for each of the root .rb files in the
  # tutorials folder.
  #
  # @yield [String] filename
  #
  # @return [Array<String>] files
  def self.rb_files(include_subfolders = false)
    tutorials_path = File.join(__dir__, 'tutorials')
    folders = include_subfolders ? '**' : '*'
    tutorials_pattern = File.join(tutorials_path, folders, '*.rb')
    Dir.glob(tutorials_pattern).each { |filename|
      yield filename
    }
  end

  # Utility method to mute Ruby warnings for whatever is executed by the block.
  def self.mute_warnings(&block)
    old_verbose = $VERBOSE
    $VERBOSE = nil
    result = block.call
  ensure
    $VERBOSE = old_verbose
    result
  end

  # Utility method to quickly reload the tutorial files. Useful for development.
  #
  # @return [Integer] Number of files reloaded.
  def self.reload
    self.mute_warnings do
      files = self.rb_files(true) { |filename|
        load filename
      }
      puts "Reloaded #{files.size} files" if $VERBOSE
      files.size
    end
  end

  # This runs when this file is loaded and adds the location of each of the
  # tutorials folders to the load path such that the tutorials can be loaded
  # into SketchUp directly from the repository.
  self.rb_files { |filename|
    begin
      path = File.dirname(filename)
      $LOAD_PATH << path
      require filename
    rescue LoadError => error
      warn "Failed to load: #{filename}"
      warn error.inspect
      warn error.description
    end
  }

end # module Examples
