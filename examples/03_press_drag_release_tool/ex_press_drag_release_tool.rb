# Copyright 2021 Trimble Inc
# Licensed under the MIT license

# This demonstrate how to improve a custom Ruby tool to allow optional
# press+drag+release drawing style.

require 'sketchup.rb'
require 'extensions.rb'

module Examples
  module PressDragReleaseTool

    unless file_loaded?(__FILE__)
      ex = SketchupExtension.new('Press+Drag+Release Tool', 'ex_press_drag_release_tool/main')
      ex.description = 'SketchUp Ruby API example for press+drag+release drawing style.'
      ex.version     = '1.0.0'
      ex.copyright   = 'Trimble Inc © 2021'
      ex.creator     = 'SketchUp'
      Sketchup.register_extension(ex, true)
      file_loaded(__FILE__)
    end

  end
end
