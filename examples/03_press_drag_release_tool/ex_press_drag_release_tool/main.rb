# Copyright 2021 Trimble Inc
# Licensed under the MIT license

require 'sketchup.rb'

module Examples
  module PressDragReleaseTool

    class LineTool

      # Threshold in logical screen pixels for when the mouse is considered to
      # be dragged.
      DRAG_THRESHOLD = 10

      def activate
        @mouse_ip = Sketchup::InputPoint.new
        @picked_first_ip = Sketchup::InputPoint.new

        # Track where mouse was pressed down so we can compare its position when
        # later released.
        @mouse_down = ORIGIN

        update_ui
      end

      def deactivate(view)
        view.invalidate
      end

      def resume(view)
        update_ui
        view.invalidate
      end

      def suspend(view)
        view.invalidate
      end

      def onCancel(reason, view)
        reset_tool
        view.invalidate
      end

      def onMouseMove(flags, x, y, view)
        if picked_first_point?
          @mouse_ip.pick(view, x, y, @picked_first_ip)

          # Print the length of the previewed line to the measurement bar.
          # Printing a Length object (as opposed to a float) automatically
          # formats it according to the model units.
          Sketchup.vcb_value = @mouse_ip.position.distance(@picked_first_ip.position)
        else
          @mouse_ip.pick(view, x, y)
        end
        view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid?
        view.invalidate
      end

      def onLButtonDown(flags, x, y, view)
        # Track where in screen space mouse is pressed down.
        @mouse_down = Geom::Point3d.new(x, y)

        if picked_first_point? && create_edge > 0
          # When the user have picked a start point and then picks another point
          # we create an edge and try to create new faces from that edge.
          # Like the native tool we reset the tool if it created new faces.
          reset_tool
        else
          # If no face was created we let the user chain new edges to the last
          # input point.
          @picked_first_ip.copy!(@mouse_ip)
        end

        update_ui
        view.invalidate
      end

      def onLButtonUp(flags, x, y, view)
        if @mouse_down.distance([x, y]) > DRAG_THRESHOLD
          # Mouse is released far enough away from where it was pressed to be
          # considered to be dragged there.

          create_edge

          # When drag-drawing, it feels odd to chain line drawing and we
          # consistently reset the tool instead.
          # You can try only calling this method if create_edge returns a
          # positive number, to experience the other behavior.
          reset_tool
        end
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
        bounds = Geom::BoundingBox.new
        bounds.add(picked_points)
        bounds
      end

      private

      def update_ui
        if picked_first_point?
          Sketchup.status_text = 'Select end point.'
        else
          Sketchup.status_text = 'Select start point.'
        end

        Sketchup.vcb_label = 'Length'
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

      def draw_preview(view)
        points = picked_points
        return unless points.size == 2
        view.set_color_from_line(*points)
        view.line_width = 1
        view.line_stipple = ''
        view.draw(GL_LINES, points)
      end

      # Returns the number of created faces.
      def create_edge
        model = Sketchup.active_model
        model.start_operation('Edge', true)
        edge = model.active_entities.add_line(picked_points)
        num_faces = edge.find_faces || 0 # API returns nil instead of 0.
        model.commit_operation

        num_faces
      end

    end # class LineTool


    def self.activate_line_tool
      Sketchup.active_model.select_tool(LineTool.new)
    end

    unless file_loaded?(__FILE__)
      menu = UI.menu('Plugins')
      menu.add_item('03 Press+Drag+Release Tool Example') {
        self.activate_line_tool
      }
      file_loaded(__FILE__)
    end

  end
end
