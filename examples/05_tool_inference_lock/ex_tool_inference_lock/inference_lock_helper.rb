module Examples
  module ToolInferenceLock
    # Helper object to lock tool inference using Shift or arrow keys.
    class InferenceLockHelper
      # Create InferenceLockHelper object.
      def initialize
        @axis_lock = nil
        @mouse_x = nil
        @mouse_y = nil
      end

      # Call this method from +onKeyDown+.
      #
      # After calling this method, also re-pick your input point, as the
      # inference lock may have changed.
      #
      # @param key [Integer]
      # @param view [Sketchup::View]
      # @param active_ip [Sketchup::InputPoint]
      #   The InputPoint currently used to pick points.
      # @param reference_ip [Sketchup::InputPoint]
      #   An InputPoint marking where the current operation was started.
      def on_keydown(key, view, active_ip, reference_ip = active_ip)
        if key == CONSTRAIN_MODIFIER_KEY
          try_lock_constraint(view, active_ip)
        else
          try_lock_axis(key, view, reference_ip)
        end
      end

      # Call this method from +onKeyUp+.
      #
      # After calling this method, also re-pick your input point, as the
      # inference lock may have changed.
      #
      # @param key [Integer]
      # @param view [Sketchup::View]
      def on_keyup(key, view)
        return unless key == CONSTRAIN_MODIFIER_KEY
        return if @axis_lock

        # Calling this method with no argument unlocks inference.
        view.lock_inference
      end

      # Remove any inference locking.
      # This should typically be called when the user resets the tool.
      # Removing inference locking using Shift and arrow keys is handled by
      # +handle_keydown+ and +handle_keyup+.
      def unlock
        @axis_lock = nil
        # Calling this method with no argument unlocks inference.
        Sketchup.active_model.active_view.lock_inference
      end

      private

      # Try picking a constraint lock.
      #
      # @param view [Sketchup::View]
      # @param active_ip [Sketchup::InputPoint]
      #   The InputPoint currently used to pick points.
      def try_lock_constraint(view, active_ip)
        return if @axis_lock
        return unless active_ip.valid?

        view.lock_inference(active_ip)
      end

      # Try picking an axis lock for given keycode.
      #
      # @param key [Integer]
      # @param view [Sketchup::View]
      # @param reference_ip [Sketchup::InputPoint]
      #   An InputPoint marking where the current operation was started.
      def try_lock_axis(key, view, reference_ip)
        return unless reference_ip.valid?

        case key
        when VK_RIGHT
          lock_inference_axis([reference_ip.position, view.model.axes.xaxis], view)
        when VK_LEFT
          lock_inference_axis([reference_ip.position, view.model.axes.yaxis], view)
        when VK_UP
          lock_inference_axis([reference_ip.position, view.model.axes.zaxis], view)
        end
      end

      # Unlock inference lock to axis, if there is any.
      #
      # @param view [Sketchup::view]
      def unlock_axis(view)
        # Any inference lock not done with `lock_inference_axis` should be kept.
        # This method is only concerned with inference locks to the axes.
        return unless @axis_lock

        @axis_lock = nil
        # Calling this method with no argument unlocks inference.
        view.lock_inference
      end

      # Lock inference to an axis or unlock if already locked to that very axis.
      #
      # @param line [Array<(Geom::Point3d, Geom::Vector3d)>]
      # @param view [Sketchup::View]
      def lock_inference_axis(line, view)
        return unlock_axis(view) if line == @axis_lock

        @axis_lock = line
        view.lock_inference(
          Sketchup::InputPoint.new(line[0]),
          Sketchup::InputPoint.new(line[0].offset(line[1]))
        )
      end
    end
  end
end
