# Copyright 2016 Trimble Inc
# Licensed under the MIT license

module Examples

  # Finds and returns the filename for each of the root .rb files in the
  # examples folder.
  #
  # @yield [String] filename
  #
  # @return [Array<String>] files
  def self.rb_files(include_subfolders = false)
    examples_path = File.join(__dir__, 'examples')
    folders = include_subfolders ? '**' : '*'
    examples_pattern = File.join(examples_path, folders, '*.rb')
    Dir.glob(examples_pattern).each { |filename|
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
      load __FILE__
      files = self.rb_files(true) { |filename|
        load filename
      }
      puts "Reloaded #{files.size} files" if $VERBOSE
      files.size + 1
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
