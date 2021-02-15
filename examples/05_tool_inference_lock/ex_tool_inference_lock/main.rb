# Copyright 2021 Trimble Inc
# Licensed under the MIT license

require 'sketchup.rb'
require 'ex_tool_inference_lock/inference_lock_helper'

module Examples
  module ToolInferenceLock

    class LineTool

      # Threshold in logical screen pixels for when the mouse is considered to
      # be dragged.
      DRAG_THRESHOLD = 10

      def activate
        @mouse_ip = Sketchup::InputPoint.new
        @picked_first_ip = Sketchup::InputPoint.new
        @mouse_position = ORIGIN
        @mouse_down = ORIGIN
        @distance = 0

        # Create a InferenceLockHelper object to use in this tool.
        # See inference_lock_helper.rb for details.
        @inference_lock_helper = InferenceLockHelper.new

        update_ui
      end

      def deactivate(view)
        @inference_lock_helper.unlock
        view.invalidate
      end

      def enableVCB?
        picked_first_point?
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

      def onKeyDown(key, _repeat, _flags, view)
        @inference_lock_helper.on_keydown(key, view, @mouse_ip, @picked_first_ip)
        pick_mouse_position(view)
      end

      def onKeyUp(key, _repeat, _flags, view)
        @inference_lock_helper.on_keyup(key, view)
        pick_mouse_position(view)
      end

      def onMouseMove(flags, x, y, view)
        # Memorize mouse positions so we can do the InputPoint picking again
        # when inference lock changes.
        @mouse_position = Geom::Point3d.new(x, y, 0)

        # Breaking out the normal mouse move logic to a method that can also be
        # called when inference lock changes.
        pick_mouse_position(view)
      end

      def onLButtonDown(flags, x, y, view)
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
          create_edge
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

      def onUserText(text, view)
        begin
          distance = text.to_l
        rescue ArgumentError
          UI.messagebox('Invalid length')
          return
        end
        direction = picked_points[1] - picked_points[0]
        end_point = picked_points[0].offset(direction, distance)
        @mouse_ip = Sketchup::InputPoint.new(end_point)

        # If faces are created when creating the edge, reset the tool.
        # Otherwise keep drawing edges.
        if create_edge > 0
          reset_tool
        else
          @picked_first_ip.copy!(@mouse_ip)
        end

        view.invalidate
      rescue ArgumentError
        Ui.messagebox('Invalid length')
      end

      def draw(view)
        draw_preview(view)

        view.line_width = 1
        @mouse_ip.draw(view) if @mouse_ip.display?
      end

      def getExtents
        bounds = Geom::BoundingBox.new
        bounds.add(picked_points)
        bounds
      end

      private

      # This is the input point picking logic you typically see in OnMouseMove.
      # This code is broken out as a separate method to be able to update the
      # input points when the inference lock changes.
      def pick_mouse_position(view)
        if picked_first_point?
          @mouse_ip.pick(view, @mouse_position.x, @mouse_position.y, @picked_first_ip)
          @distance = @mouse_ip.position.distance(@picked_first_ip.position)
          update_ui
        else
          @mouse_ip.pick(view, @mouse_position.x, @mouse_position.y)
        end
        view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid?
        view.invalidate
      end

      def update_ui
        # We specifically do not bloat the status text with all the arrow keys
        # and Shift key, as those are more or less universal in SketchUp.
        # Adding too much text just makes the status bar hard to read.
        # However, the instructor should mention these.
        if picked_first_point?
          Sketchup.status_text = 'Select end point.'
          Sketchup.vcb_value = @distance
        else
          Sketchup.status_text = 'Select start point.'
        end

        Sketchup.vcb_label = 'Length'
      end

      def reset_tool
        @picked_first_ip.clear

        # Unlock inference when resetting the tool.
        # If the user isn't happy with the starting point, they likely aren't
        # happy with any inference lock either.
        @inference_lock_helper.unlock

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

        # When inference is locked, draw the lines 3 pixels wide.
        # This subtly but clearly the line now "snaps" into a certain direction.
        view.line_width = view.inference_locked? ? 3 : 1

        view.set_color_from_line(*points)
        view.draw(GL_LINES, points)
      end

      # Returns the number of created faces.
      def create_edge
        model = Sketchup.active_model
        model.start_operation('Edge', true)
        edge = model.active_entities.add_line(picked_points)
        num_faces = edge.find_faces || 0 # API returns nil instead of 0.
        model.commit_operation

        # Remove any inference lock once an edge is drawn.
        # Typically you don't want more than one edge locked to a single line or
        # plane.
        @inference_lock_helper.unlock

        num_faces
      end

    end # class LineTool


    def self.activate_line_tool
      Sketchup.active_model.select_tool(LineTool.new)
    end

    unless file_loaded?(__FILE__)
      menu = UI.menu('Plugins')
      menu.add_item('05 Tool Inference Lock Example') {
        self.activate_line_tool
      }
      file_loaded(__FILE__)
    end

  end
end
