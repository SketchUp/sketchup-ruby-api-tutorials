# Copyright 2021 Trimble Inc
# Licensed under the MIT license

# This demonstrate an optional select stage in a tool.

require 'sketchup.rb'
require 'extensions.rb'

module Examples
  module InToolSelection

    unless file_loaded?(__FILE__)
      ex = SketchupExtension.new('In Tool Selection', 'ex_in_tool_selection/main')
      ex.description = 'SketchUp Ruby API example of in tool selection.'
      ex.version     = '1.0.0'
      ex.copyright   = 'Trimble Inc © 2021'
      ex.creator     = 'SketchUp'
      Sketchup.register_extension(ex, true)
      file_loaded(__FILE__)
    end

  end
end
