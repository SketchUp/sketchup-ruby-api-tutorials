# Copyright 2016 Trimble Navigation Limited
# Licensed under the MIT license

module Examples

  # Finds and returns the filename for each of the root .rb files in the
  # tutorials folder.
  #
  # @yield filename
  def self.root_rb_files
    tutorials_path = File.join(__dir__, 'tutorials')
    tutorials_pattern = File.join(tutorials_path, '*', '*.rb')
    Dir.glob(tutorials_pattern) { |filename|
      yield filename
    }
    nil
  end

  # Utility method to quickly reload the tutorial files. Useful for development.
  def self.reload
    self.root_rb_files { |filename|
      load filename
    }
    nil
  end

  # This runs when this file is loaded and adds the location of each of the
  # tutorials folders to the load path such that the tutorials can be loaded
  # into SketchUp directly from the repository.
  self.root_rb_files { |filename|
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
