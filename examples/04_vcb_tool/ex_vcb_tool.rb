# Copyright 2021 Trimble Inc
# Licensed under the MIT license

# This demonstrate how to improve a custom Ruby tool to allow precise text input
# in the measurement bar (aka VCB).

require 'sketchup.rb'
require 'extensions.rb'

module Examples
  module VCBTool

    unless file_loaded?(__FILE__)
      ex = SketchupExtension.new('Measurement Bar', 'ex_vcb_tool/main')
      ex.description = 'SketchUp Ruby API example of tool Measurement Bar support.'
      ex.version     = '1.0.0'
      ex.copyright   = 'Trimble Inc © 2021'
      ex.creator     = 'SketchUp'
      Sketchup.register_extension(ex, true)
      file_loaded(__FILE__)
    end

  end
end
