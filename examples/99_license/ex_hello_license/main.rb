# Copyright 2018 Trimble Inc
# Licensed under the MIT license

require 'sketchup.rb'

module Examples
  module HelloLicense

    def self.create_cube
      # Performing a license check before executing the extension's commands.
      # The extension id is kept as a local variable as constants and
      # class/instance variables are too easy to tamper with.
      ext_id = '6cce9800-40b0-4dd9-9671-8d55a05ae1e8'
      license = Sketchup::Licensing.get_extension_license(ext_id)
      unless license.licensed?
        UI::messagebox('Could not obtain a valid license.')
        return
      end

      # If license is ok then normal execution will proceed:
      model = Sketchup.active_model
      model.start_operation('Create Cube', true)
      group = model.active_model.add_group
      entities = group.entities
      points = [
        Geom::Point3d.new(0,   0,   0),
        Geom::Point3d.new(1.m, 0,   0),
        Geom::Point3d.new(1.m, 1.m, 0),
        Geom::Point3d.new(0,   1.m, 0)
      ]
      face = entities.add_face(points)
      face.pushpull(-1.m)
      model.commit_operation
    end

    unless file_loaded?(__FILE__)
      # Menus and toolbars are always visible, regardless of the extension's
      # license state. This is to avoid confusing for the user. This require
      # the commands themselves to have a license check. As seen in the example
      # above, it's recommended to provide a message back to the user.
      menu = UI.menu('Plugins')
      menu.add_item('99 Create Cube Example') {
        self.create_cube
      }
      file_loaded(__FILE__)
    end

    # Fetching a license here so that it will be checked by SketchUp during
    # startup. This will include the extension in the dialog that warns about
    # missing licenses.
    ext_id = '6cce9800-40b0-4dd9-9671-8d55a05ae1e8'
    ext_lic = Sketchup::Licensing.get_extension_license(ext_id)

  end # module HelloLicense
end # module Examples
