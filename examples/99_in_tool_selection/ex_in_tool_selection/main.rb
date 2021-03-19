# Copyright 2021 Trimble Inc
# Licensed under the MIT license

require 'ex_in_tool_selection/inference_lock_helper'

module Examples
  module InToolSelection

    class ComponentMoveTool

      # Threshold in logical screen pixels for when the mouse is considered to
      # be dragged.
      DRAG_THRESHOLD = 10

      def initialize
        @mouse_ip = Sketchup::InputPoint.new
        @picked_first_ip = Sketchup::InputPoint.new
        @mouse_position = ORIGIN
        @mouse_down = ORIGIN
        @distance = 0

        # Create a InferenceLockHelper object to use in this tool.
        # See inference_lock_helper.rb for details.
        @inference_lock_helper = InferenceLockHelper.new

        # Empty the selection if the tool can't use it.
        # Otherwise keep this preselection.
        Sketchup.active_model.selection.clear unless valid_selection?

        # The tool selection is tracked separately from the SketchUp selection.
        # When we are in the selection stage we want to temporarily select
        # hovered entities for previewing them as selected, but our tool logic
        # treats the selection as empty until the user clicks.
        #
        # Native tools can preview entities as selected without actually
        # adding them to the selection, but the Ruby API doesn't support this.
        @selection = Sketchup.active_model.selection.to_a

        # Remember whether tool was activated with preselection or not as this
        # affect how the tool resets.
        @preselected = !Sketchup.active_model.selection.empty?

        # The entity being hovered when at the selection stage.
        @hovered_entity = nil

        # Whether the the tool is able to interact with the hovered entity.
        # This affects what mouse cursor the tool uses.
        @valid_hovered_entity = false
      end

      def activate
        update_ui
      end

      def deactivate(view)
        @inference_lock_helper.unlock
        view.model.abort_operation if @in_operation
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
        if @selection.empty?
          # If the tool selection is empty, try picking the hovered object.
          try_select_entity(view, x, y)
        end

        @mouse_position = Geom::Point3d.new(x, y, 0)
        pick_mouse_position(view)
      end

      def onLButtonDown(flags, x, y, view)
        @mouse_down = Geom::Point3d.new(x, y)

        # If tool selection is empty, select our hovered entity.
        # If we already have a selection, we use it.
        if @selection.empty?
          @selection = view.model.selection.to_a
        end

        return if @selection.empty?

        # For a Move or Rotate like tool, we can select a starting point in the
        # same mouse click as we select an entity. For Scale or other tools
        # where you need to select a handle, this logic is typically slightly
        # different, and separate click is needed.

        if !picked_first_point?
          start_move(view)
        else
          end_move(view)
        end

        update_ui
        view.invalidate
      end

      def onLButtonUp(flags, x, y, view)
        if @mouse_down.distance([x, y]) > DRAG_THRESHOLD
          end_move(view)
        end
      end

      # Here we have hard coded a special ID for the move cursor in SketchUp.
      # Normally you would use `UI.create_cursor(cursor_path, 0, 0)` instead
      # with your own custom cursor bitmap:
      #
      #   CURSOR = UI.create_cursor(cursor_path, 0, 0)
      MOVE_CURSOR = 641
      INVALID_CURSOR = 663

      def onSetCursor
        # Note that `onSetCursor` is called frequently so you should not do much
        # work here. At most you switch between different cursor representing
        # the state of the tool.

        # Cursor depends on the tool state and hovered entity.
        # If the user is at the selection stage and hover a non-selectable
        # entity, they se an invalid-cursor.
        # Hovering empty space in SketchUp doesn't show the invalid-cursor,
        # even if empty space can't be selected.
        if !picked_first_point? && @hovered_entity && !@valid_hovered_entity
          UI.set_cursor(INVALID_CURSOR)
        else
          UI.set_cursor(MOVE_CURSOR)
        end
      end

      def onUserText(text, view)
        begin
          distance = text.to_l
        rescue ArgumentError
          UI.messagebox('Invalid length')
          return
        end
        direction = picked_points[0].vector_to(picked_points[1])
        end_point = picked_points[0].offset(direction, distance)
        @mouse_ip = Sketchup::InputPoint.new(end_point)

        # Move the selected entities and exit the move stage.
        do_move(view)
        end_move(view)

        view.invalidate
      end

      def draw(view)
        draw_preview_line(view)

        view.line_width = 1

        # Draw inputpoint (including tooltip) so the user knows where exactly
        # where it is.
        # However, don't draw it when at the selection stage and not hovering
        # a selectable entity. Doing so would suggest you could click to select
        # a point and proceed to the next tool stage.
        if picked_first_point? || (@hovered_entity && @valid_hovered_entity)
          @mouse_ip.draw(view)
          view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid?
        end
      end

      def getExtents
        bounds = Geom::BoundingBox.new
        bounds.add(picked_points) unless picked_points.empty?
        bounds
      end

      private

      # Check if an entity is allowed to be selected by this tool.
      def valid_entity?(entity)
        # In this somewhat artificial example we only allow components to be
        # moved. In a real life example you'd typically filter entities by
        # other criteria.

        # To replicate native Move, Rotate and Scale tools, allow all
        # DrawingElements except Axes.
        ### !entity.is_a?(Sketchup::Axes)

        # Another typical use case is a custom tool that edits some property of
        # a custom objects, e.g. Bezier curve control points or wall corner
        # points. For this, you'd typically check for the entity being a group
        # and/or component, and if it has the attribute dictionary holding your
        # custom properties.
        ### entity.is_a?(Sketchup::Group) && entity.attribute_dictionary("TurboWall2000")

        entity.is_a?(Sketchup::ComponentInstance)
      end

      # Check if the selection as a whole is valid for this tool.
      def valid_selection?
        selection = Sketchup.active_model.selection

        selection.size == 1 && valid_entity?(selection.first)
      end

      # Try selecting the entity under the mouse cursor, if the tool allows it.
      def try_select_entity(view, x, y)
        view.model.selection.clear

        pickhelper = view.pick_helper(x, y)
        @hovered_entity = pickhelper.best_picked
        return unless @hovered_entity

        @valid_hovered_entity = valid_entity?(@hovered_entity)
        return unless @valid_hovered_entity

        view.model.selection.add(@hovered_entity)
      end

      # Start model operation and enter the tool move stage.
      def start_move(view)
        # Typically you'd just copy the active picking InputPoint state into
        # the reference InputPoint here.
        ### @picked_first_ip.copy!(@mouse_ip)
        # However, since we are moving the geometry that the InputPoint has
        # gotten its position from, this would also cause the reference
        # InputPoint to move. This would lead to the distance reported in the
        # VCB to be 0 and the preview line to be missing.
        # Instead just create a new InputPoint with a fixed location in space.
        # See https://github.com/SketchUp/api-issue-tracker/issues/618
        # See https://github.com/SketchUp/api-issue-tracker/issues/452
        @picked_first_ip = Sketchup::InputPoint.new(@mouse_ip.position)

        # Wrap model changes in an operation so it can be undone in one step.
        # Typically we disable drawing in operations to increase performance,
        # but here we want live updates when moving the mouse.
        view.model.start_operation("Move", false)

        # Track whether we are in an operation so we can abort it if the user
        # activates another tool.
        @in_operation = true

        # Track the mouse position between events so we can update the position
        # of the selected entities.
        @last_mouse_position = @mouse_ip.position
      end

      # Update the position of the selected entities.
      # Called on each mouse move or when entering a measurement as text.
      def do_move(view)
        return unless @last_mouse_position

        # Move entities the same distance mouse has moved since last move event.
        delta_move = @last_mouse_position.vector_to(@mouse_ip.position)
        @last_mouse_position = @mouse_ip.position

        view.model.active_entities.transform_entities(delta_move, @selection)
      end

      # Leave the tool move stage and close the operation.
      def end_move(view)
        view.model.commit_operation
        @in_operation = false

        @picked_first_ip.clear
        @inference_lock_helper.unlock

        # If tool was activated with a pre-selection, keep the selection and let
        # the user pick a starting point anywhere. Otherwise, drop the selection
        # and select whatever the user clicks when starting next move operation.
        reset_tool unless @preselected
      end

      def pick_mouse_position(view)
        if !picked_first_point?
          @mouse_ip.pick(view, @mouse_position.x, @mouse_position.y)
        else
          # If we could, we would want the InputPoint to ignore entities in
          # @selection. We are currently getting some quite strange behavior
          # when we get inference from the entities we are already moving.
          # For instance you can't always move an object away from the camera,
          # as the entities being moved is in front of the point you'd want to
          # pick.
          # https://github.com/SketchUp/api-issue-tracker/issues/452
          @mouse_ip.pick(view, @mouse_position.x, @mouse_position.y, @picked_first_ip)
          @distance = @mouse_ip.position.distance(@picked_first_ip.position)
          update_ui

          do_move(view)
        end
        view.invalidate
      end

      def update_ui
        if @selection.empty?
          Sketchup.status_text = 'Select a component.'
        elsif !picked_first_point?
          Sketchup.status_text = 'Select start point.'
        else
          Sketchup.status_text = 'Select end point.'

          # Only update the VCB text if is different from when last set.
          # This prevents the text the user is currently writing from being
          # overridden at key events affecting the inference.
          Sketchup.vcb_value = @distance unless @vcb_cache == @distance
          @vcb_cache = @distance
        end

        Sketchup.vcb_label = 'Distance'
      end

      def reset_tool
        @picked_first_ip.clear
        @inference_lock_helper.unlock
        Sketchup.active_model.selection.clear
        @selection.clear
        @preselected = false

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

      def draw_preview_line(view)
        points = picked_points
        return unless points.size == 2

        # Currently there is an API bug that makes the line stipple scale with
        # the line width, which produces an inconsistent look from that of
        # native tools.
        # https://github.com/SketchUp/api-issue-tracker/issues/229
        view.line_width = view.inference_locked? ? 3 : 1
        view.set_color_from_line(*points)
        view.line_stipple = "_"
        view.draw(GL_LINES, points)
      end

    end

    def self.activate_move_tool
      Sketchup.active_model.select_tool(ComponentMoveTool.new)
    end

    unless file_loaded?(__FILE__)
      menu = UI.menu('Plugins')
      menu.add_item('99 In Tool Selection') {
        self.activate_move_tool
      }
      file_loaded(__FILE__)
    end

  end
end
