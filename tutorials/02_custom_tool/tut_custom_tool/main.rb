# Copyright 2016 Trimble Navigation Limited
# Licensed under the MIT license

require 'sketchup.rb'

module Examples
  module CustomTool

    # Custom tools are creating a class which respond to various callback
    # methods from SketchUp.
    class LineTool

      # The `actvate` method is called whenever the tool is activated. This is
      # where you initialize and prepare your tool.
      # Note that this is different from Ruby's `initialize` method. You can
      # reuse Tool instances in which case `initialize` would not be the best
      # place to set up the tool.
      def activate

        # We will need to sample 3d points from the model as the user interact
        # with the tool and the model. For this we use InputPoint which also
        # add some inference-magic.
        # We need to sample the 3d point under the mouse cursor and keep a
        # reference of what the user clicks on.
        @mouse_ip = Sketchup::InputPoint.new
        @picked_first_ip = Sketchup::InputPoint.new

        # We make sure to call out utility method that updates the statusbar
        # with instructions on how to use the tool.
        update_ui
      end

      # This is called when the user switch to a new tool. It's recommended to
      # always call view.invalidate in order to make sure we clear out any
      # custom drawings done to the viewport. Otherwise it might linger around
      # for a moment and confuse the user.
      def deactivate(view)
        view.invalidate
      end

      # Tools can be temporarily suspended and resumed. One example of this is
      # when the user use the Orbit tool by pressing the middle mouse button.
      # In order to make sure we update our statusbar text and custom viewport
      # drawing we need to do that here.
      def resume(view)
        update_ui
        view.invalidate
      end

      # Tools can be interrupted for various reasons. In this example tool we
      # simply reset it regardless, but if you need finer granularity you can
      # check the reason code.
      #
      # 0: The user canceled the current operation by hitting the escape key.
      # 1: The user re-selected the same tool from the toolbar or menu.
      # 2: The user did an undo while the tool was active.
      def onCancel(reason, view)
        reset_tool
        view.invalidate
      end

      def onMouseMove(flags, x, y, view)
        # We want to sample the 3d point under the cursor as the user moves it.
        if picked_first_point?
          # When the user have picked a start point we use that while picking in
          # order for SketchUp to do it's inference magic.
          # Note that if you want to allow the user to lock inference you need
          # to implement `view.lock_inference`. This will be described in a
          # later tutorial.
          @mouse_ip.pick(view, x, y, @picked_first_ip)
        else
          # When the user haven't picked a start point yet we just use the
          # x and y coordinates of the cursor.
          @mouse_ip.pick(view, x, y)
        end
        # Here we let SketchUp display it's hints to have it's inferensing,
        # similar to how the native tools do it.
        view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid?
        # Lastly we want to ensure we update the view.
        view.invalidate
      end

      # When the user clicks in the viewport we want to create edges based on
      # the input points we have collected.
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
        # As always we want to update the statusbar text and view.
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

      # The `draw` method is called every time SketchUp updates the viewport.
      # You should take care to do as little work in this method. If you need to
      # calculate things to draw it its best to cache the data in order to get
      # better frame rate.
      def draw(view)
        draw_preview(view)
        @mouse_ip.draw(view) if @mouse_ip.display?
      end

      # When you use `view.draw` and draw things outside the boundingbox of
      # the existing model geometry you will see that things get clipped.
      # In order to make sure everything you draw is visible you must return
      # a boundingbox here which define the 3d model space you draw to.
      def getExtents
        bb = Geom::BoundingBox.new
        bb.add(picked_points)
        bb
      end

      # In this example we put all the logic in the tool class itself. For more
      # complex tools you probably want to move that logic into it's own class
      # in order to reduce complexity. If you are familiar with the MVC pattern
      # then consider a tool class a controller - you want to keep it short and
      # simple.
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


    # A utility method to activate the tool. This is defined here for easy
    # reuse as well as making it easier to debug while developing. If this
    # code was directly in the `add_item` block and you needed to make changes
    # to how you activate the tool then it would not take effect until you
    # restarted SketchUp due to the load guard.
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
