# Copyright 2016 Trimble Inc
# Licensed under the MIT license

# This demonstrate how to create a custom Ruby tool that lets the user pick
# points in the model to create a cube.

require 'sketchup.rb'
require 'extensions.rb'

module Examples
  module CustomTool

    unless file_loaded?(__FILE__)
      ex = SketchupExtension.new('Custom Tool', 'ex_custom_tool/main')
      ex.description = 'SketchUp Ruby API example creating a custom tool.'
      ex.version     = '1.0.0'
      ex.copyright   = 'Trimble Navigations © 2016'
      ex.creator     = 'SketchUp'
      Sketchup.register_extension(ex, true)
      file_loaded(__FILE__)
    end

  end # module CustomTool
end # module Examples
