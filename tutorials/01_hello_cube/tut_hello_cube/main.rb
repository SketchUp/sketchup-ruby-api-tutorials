# Copyright 2016 Trimble Inc
# Licensed under the MIT license

require 'sketchup.rb'

module Examples
  module HelloCube

    # This method creates a simple cube inside of a group in the model.
    def self.create_cube
      # We need a reference to the currently active model. The SketchUp API
      # currently only lets you work on the active model. Under Windows there
      # will be only one model open at a time, but under OS X there might be
      # multiple models open.
      #
      # Beware that if there is no model open under OS X then `active_model`
      # will return nil. In this example we ignore that for simplicity.
      model = Sketchup.active_model

      # Whenever you make changes to the model you must take care to use
      # `model.start_operation` and `model.commit_operation` to wrap everything
      # into a single undo step. Otherwise the user risks not being able to
      # undo everything and she may loose work.
      #
      # Making sure your model changes are undoable in a single undo step is a
      # requirement of the Extension Warehouse submission quality checks.
      #
      # Note that the first argument name is a string that will be appended to
      # the Edit > Undo menu - so make sure you name your operations something
      # the users can understand.
      model.start_operation('Create Cube', true)

      # Creating a group via the API is slightly different from creating a
      # group via the UI.  Via the UI you create the faces first, then group
      # them. But with the API you create the group first and then add its
      # content directly to the group.
      group = model.active_entities.add_group
      entities = group.entities

      # Here we define a set of 3d points to create a 1x1m face. Note that the
      # internal unit in SketchUp is inches. This means that regardless of the
      # model unit settings the 3d data is always stored in inches.
      #
      # In order to make it easier work with lengths the Numeric class has
      # been extended with some utility methods that let us write stuff like
      # `1.m` to represent a meter instead of `39.37007874015748`.
      points = [
        Geom::Point3d.new(0,   0,   0),
        Geom::Point3d.new(1.m, 0,   0),
        Geom::Point3d.new(1.m, 1.m, 0),
        Geom::Point3d.new(0,   1.m, 0)
      ]

      # We pass the points to the `add_face` method and keep the returned
      # reference to the face as we want to keep working with it.
      #
      # Note that normally the orientation (its normal) is a result of the order
      # of the 3d points you use to create it. The exception is when you create
      # a face on the ground plane (all points with z == 0) then it will always
      # be face down.
      face = entities.add_face(points)

      # Here we invoke SketchUp's push-pull functionality on the face. But note
      # that we must use a negative number in order for it to extrude upwards
      # in the positive direction of the Z-axis. This is because SketchUp
      # forced this face on the ground place to be face down.
      face.pushpull(-1.m)

      # Finally we are done and we close the operation. In production you will
      # want to catch errors and abort to clean up if your function failed.
      # But for simplicity we won't do this here.
      model.commit_operation
    end

    # Here we add a menu item for the extension. Note that we again use a
    # load guard to prevent multiple menu items from accidentally being
    # created.
    unless file_loaded?(__FILE__)

      # We fetch a reference to the top level menu we want to add to. Note that
      # we use "Plugins" here which was the old name of the "Extensions" menu.
      # By using "Plugins" you remain backwards compatible.
      menu = UI.menu('Plugins')

      # We add the menu item directly to the root of the menu in this example.
      # But if you plan to add multiple items per extension we recommend you
      # group them into a sub-menu in order to keep things organized.
      menu.add_item('01 Create Cube Example') {
        self.create_cube
      }

      file_loaded(__FILE__)
    end

  end # module HelloCube
end # module Examples
