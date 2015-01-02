class TrafficLight
  state_machine initial: :stop do
    event :cycle do
      transition stop: :proceed, proceed: :caution, caution: :stop
    end

    state :stop do
      def color(transform)
        value = 'red'

        if block_given?
          yield value
        else
          value.send(transform)
        end

        value
      end
    end

    state all - :proceed do
      def capture_violations?
        true
      end
    end

    state :proceed do
      def color(_transform)
        'green'
      end

      def capture_violations?
        false
      end
    end

    state :caution do
      def color(_transform)
        'yellow'
      end
    end
  end

  def color(transform = :to_s)
    super
  end
end
