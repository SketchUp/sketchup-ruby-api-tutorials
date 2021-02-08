# Copyright 2018 Trimble Inc
# Licensed under the MIT license

require 'sketchup.rb'

module Examples
  module HelloSphere

    def self.create_sphere
      model = Sketchup.active_model
      model.start_operation('Create Sphere', true)
      group = model.active_entities.add_group
      # Create a filled circle which later will be revolved around itself to
      # create a sphere.
      num_segments = 48
      circle = group.entities.add_circle(ORIGIN, X_AXIS, 1.m, num_segments)
      face = group.entities.add_face(circle)
      face.reverse!
      # Create a temporary path for follow me to use to perform the revolve.
      # This path should not touch the face.
      path = group.entities.add_circle(ORIGIN, Z_AXIS, 2.m, num_segments)
      # This creates the sphere.
      face.followme(path)
      # The temporary path is no longer needed.
      group.entities.erase_entities(path)
      model.commit_operation
    end

    unless file_loaded?(__FILE__)
      menu = UI.menu('Plugins')
      menu.add_item('99 Create Sphere Example') {
        self.create_sphere
      }
      file_loaded(__FILE__)
    end

  end # module HelloSphere
end # module Examples