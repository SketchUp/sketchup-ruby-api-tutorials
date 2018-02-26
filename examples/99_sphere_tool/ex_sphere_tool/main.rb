# Copyright 2018 Trimble Inc
# Licensed under the MIT license

require 'sketchup.rb'

module Examples
  module SphereToolExample

    class SphereTool

      def activate
        @mouse_ip = Sketchup::InputPoint.new
        @picked_first_ip = Sketchup::InputPoint.new
        update_ui
      end

      def deactivate(view)
        view.invalidate
      end

      def resume(view)
        update_ui
        view.invalidate
      end

      def onCancel(reason, view)
        reset_tool
        view.invalidate
      end

      def onMouseMove(flags, x, y, view)
        if picked_first_point?
          @mouse_ip.pick(view, x, y, @picked_first_ip)
        else
          @mouse_ip.pick(view, x, y)
        end
        view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid?
        update_ui
        view.invalidate
      end

      def onLButtonDown(flags, x, y, view)
        if picked_first_point?
          create_sphere
        else
          @picked_first_ip.copy!(@mouse_ip)
        end
        update_ui
        view.invalidate
      end

      def enableVCB?
        picked_first_point?
      end

      def onUserText(text, view)
        # Ensure that the center of the sphere has been picked.
        return unless picked_first_point? && @mouse_ip.valid?
        # Try to parse the user input - this might fail, so rescue from errors.
        begin
          radius = text.to_l
          # Ensure the sphere actually have a dimension.
          raise ArgumentError if radius == 0.to_l
        rescue ArgumentError
          UI.beep
          view.tooltip = 'Invalid length entered.'
          return
        end
        # Compute the new radius from the user input.
        origin = @picked_first_ip.position
        vector = origin.vector_to(@mouse_ip)
        vector.length = radius
        tangent = origin.offset(vector, radius)
        # Everything ready to create the sphere.
        create_sphere
        update_ui
        view.invalidate
      end

      # Here we have hard coded a special ID for the pencil cursor in SketchUp.
      # Normally you would use `UI.create_cursor(cursor_path, 0, 0)` instead
      # with your own custom cursor bitmap:
      #
      #   CURSOR_PENCIL = UI.create_cursor(cursor_path, 0, 0)
      CURSOR_PENCIL = 632
      def onSetCursor
        # Note that `onSetCursor` is called frequently so you should not do much
        # work here. At most you switch between different cursor representing
        # the state of the tool.
        UI.set_cursor(CURSOR_PENCIL)
      end

      def draw(view)
        draw_preview(view)
        @mouse_ip.draw(view) if @mouse_ip.display?
      end

      def getExtents
        bb = Geom::BoundingBox.new
        bb.add(picked_points)
        bb
      end

      private

      def update_ui
        if picked_first_point?
          Sketchup.status_text = 'Select the radius of sphere or enter value'
          Sketchup.vcb_label = 'Radius'
          Sketchup.vcb_value = picked_distance
        else
          Sketchup.status_text = 'Select centre of sphere'
          Sketchup.vcb_label = 'Radius'
          Sketchup.vcb_value = ''
        end
      end

      def reset_tool
        @picked_first_ip.clear
        update_ui
      end

      def picked_first_point?
        @picked_first_ip.valid?
      end

      def picked_points
        points = []
        points << @picked_first_ip.position if picked_first_point?
        points << @mouse_ip.position if @mouse_ip.valid?
        points
      end

      def picked_distance
        if @picked_first_ip.valid? && @mouse_ip.valid?
          @picked_first_ip.position.distance(@mouse_ip)
        else
          0.to_l
        end
      end

      def draw_preview(view)
        points = picked_points
        return unless points.size == 2
        view.set_color_from_line(*points)
        view.line_width = 1
        view.line_stipple = ''
        view.draw(GL_LINES, points)
      end

      def create_sphere
        origin, tangent = picked_points
        radius = origin.distance(tangent)
        model = Sketchup.active_model
        model.start_operation('Create Sphere', true)
        group = model.active_entities.add_group
        # Create a filled circle which later will be revolved around itself to
        # create a sphere.
        num_segments = 48
        circle = group.entities.add_circle(origin, X_AXIS, radius, num_segments)
        face = group.entities.add_face(circle)
        face.reverse!
        # Create a temporary path for follow me to use to perform the revolve.
        # This path should not touch the face.
        path = group.entities.add_circle(origin, Z_AXIS, radius * 2, num_segments)
        # This creates the sphere.
        face.followme(path)
        # The temporary path is no longer needed.
        group.entities.erase_entities(path)
        model.commit_operation
        # Prepare to allow new input for new spheres.
        reset_tool
      end

    end # class SphereTool


    def self.activate_sphere_tool
      Sketchup.active_model.select_tool(SphereTool.new)
    end

    unless file_loaded?(__FILE__)
      menu = UI.menu('Plugins')
      menu.add_item('Sphere Tool Example') {
        self.activate_sphere_tool
      }
      file_loaded(__FILE__)
    end

  end # module SphereToolExample
end # module Examples
