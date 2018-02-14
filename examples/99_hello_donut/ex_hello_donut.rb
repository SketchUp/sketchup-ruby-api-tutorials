# Copyright 2018 Trimble Inc
# Licensed under the MIT license

require 'sketchup.rb'
require 'extensions.rb'

module Examples
  module HelloSphere

    unless file_loaded?(__FILE__)
      ex = SketchupExtension.new('Hello Donut', 'ex_hello_donut/main')
      ex.description = 'SketchUp Ruby API example creating a donut.'
      ex.version     = '1.0.0'
      ex.copyright   = 'Trimble Inc © 2018'
      ex.creator     = 'SketchUp'
      Sketchup.register_extension(ex, true)
      file_loaded(__FILE__)
    end

  end # module HelloSphere
end # module Examples
