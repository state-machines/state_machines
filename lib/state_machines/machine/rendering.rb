# frozen_string_literal: true

module StateMachines
  class Machine
    module Rendering
      # Gets the renderer for this machine.
      def renderer
        @renderer ||= StdioRenderer.new
      end

      # Generates a visual representation of this machine for a given format.
      def draw(**)
        renderer.draw(self, **)
      end
    end
  end
end
