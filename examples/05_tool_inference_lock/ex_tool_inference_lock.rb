# Copyright 2021 Trimble Inc
# Licensed under the MIT license

# This demonstrate how to add inference locking to a tool.

require 'sketchup.rb'
require 'extensions.rb'

module Examples
  module ToolInferenceLock

    unless file_loaded?(__FILE__)
      ex = SketchupExtension.new('Tool Inference Lock', 'ex_tool_inference_lock/main')
      ex.description = 'SketchUp Ruby API example of tool inference lock.'
      ex.version     = '1.0.0'
      ex.copyright   = 'Trimble Inc © 2021'
      ex.creator     = 'SketchUp'
      Sketchup.register_extension(ex, true)
      file_loaded(__FILE__)
    end

  end
end
