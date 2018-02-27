# Copyright 2016 Trimble Inc
# Licensed under the MIT license

require 'sketchup.rb'

module Examples
  module CustomTool

    class LineTool

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
        view.invalidate
      end

      def onLButtonDown(flags, x, y, view)
        # When the user have picked a start point and then picks another point
        # we create an edge and try to create new faces from that edge.
        num_new_faces = 0
        if picked_first_point?
          num_new_faces = create_edge
        end
        # Like the native tool we reset the tool if it created new faces.
        if num_new_faces > 0
          reset_tool
        else
          # If no face was created we let the user chain new edges to the last
          # input point.
          @picked_first_ip.copy!(@mouse_ip)
        end
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
          Sketchup.status_text = 'Select end point.'
        else
          Sketchup.status_text = 'Select start point.'
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

      def draw_preview(view)
        points = picked_points
        return unless points.size == 2
        view.set_color_from_line(*points)
        view.line_width = 1
        view.line_stipple = ''
        view.draw(GL_LINES, points)
      end

      def create_edge
        model = Sketchup.active_model
        model.start_operation('Edge', true)
        edge = model.active_entities.add_line(picked_points)
        num_faces = edge.find_faces
        model.commit_operation
        num_faces
      end

    end # class LineTool


    def self.activate_line_tool
      Sketchup.active_model.select_tool(LineTool.new)
    end

    unless file_loaded?(__FILE__)
      menu = UI.menu('Plugins')
      menu.add_item('Custom Tool Example') {
        self.activate_line_tool
      }
      file_loaded(__FILE__)
    end

  end # module CustomTool
end # module Examples
