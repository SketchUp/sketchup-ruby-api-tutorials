# Copyright 2018 Trimble Inc
# Licensed under the MIT license

require 'sketchup.rb'
require 'extensions.rb'

module Examples
  module SphereToolExample

    unless file_loaded?(__FILE__)
      ex = SketchupExtension.new('Sphere Tool Example', 'ex_sphere_tool/main')
      ex.description = 'SketchUp Ruby API example creating a sphere.'
      ex.version     = '1.0.0'
      ex.copyright   = 'Trimble Inc © 2018'
      ex.creator     = 'SketchUp'
      Sketchup.register_extension(ex, true)
      file_loaded(__FILE__)
    end

  end # module SphereToolExample
end # module Examples
