[![Build Status](https://travis-ci.org/state-machines/state_machines.svg?branch=master)](https://travis-ci.org/state-machines/state_machines)
[![Code Climate](https://codeclimate.com/github/state-machines/state_machines.svg)](https://codeclimate.com/github/state-machines/state_machines)
# State Machines

State Machines adds support for creating state machines for attributes on any Ruby class.

*Please note that multiple integrations are available for [Active Model](https://github.com/state-machines/state_machines-activemodel), [Active Record](https://github.com/state-machines/state_machines-activerecord), [Mongoid](https://github.com/state-machines/state_machines-mongoid) and more in the [State Machines organisation](https://github.com/state-machines).*  If you want to save state in your database, **you need one of these additional integrations**.

## Installation

Add this line to your application's Gemfile:

    gem 'state_machines'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install state_machines

## Usage

### Example

Below is an example of many of the features offered by this plugin, including:

* Initial states
* Namespaced states
* Transition callbacks
* Conditional transitions
* State-driven instance behavior
* Customized state values
* Parallel events
* Path analysis

Class definition:

```ruby
class Vehicle
  attr_accessor :seatbelt_on, :time_used, :auto_shop_busy

  state_machine :state, initial: :parked do
    before_transition parked: any - :parked, do: :put_on_seatbelt
    
    after_transition on: :crash, do: :tow
    after_transition on: :repair, do: :fix
    after_transition any => :parked do |vehicle, transition|
      vehicle.seatbelt_on = false
    end

    after_failure on: :ignite, do: :log_start_failure

    around_transition do |vehicle, transition, block|
      start = Time.now
      block.call
      vehicle.time_used += Time.now - start
    end

    event :park do
      transition [:idling, :first_gear] => :parked
    end

    event :ignite do
      transition stalled: same, parked: :idling
    end

    event :idle do
      transition first_gear: :idling
    end

    event :shift_up do
      transition idling: :first_gear, first_gear: :second_gear, second_gear: :third_gear
    end

    event :shift_down do
      transition third_gear: :second_gear, second_gear: :first_gear
    end

    event :crash do
      transition all - [:parked, :stalled] => :stalled, if: ->(vehicle) {!vehicle.passed_inspection?}
    end

    event :repair do
      # The first transition that matches the state and passes its conditions
      # will be used
      transition stalled: :parked, unless: :auto_shop_busy
      transition stalled: same
    end

    state :parked do
      def speed
        0
      end
    end

    state :idling, :first_gear do
      def speed
        10
      end
    end

    state all - [:parked, :stalled, :idling] do
      def moving?
        true
      end
    end

    state :parked, :stalled, :idling do
      def moving?
        false
      end
    end
  end

  state_machine :alarm_state, initial: :active, namespace: :'alarm' do
    event :enable do
      transition all => :active
    end

    event :disable do
      transition all => :off
    end

    state :active, :value => 1
    state :off, :value => 0
  end

  def initialize
    @seatbelt_on = false
    @time_used = 0
    @auto_shop_busy = true
    super() # NOTE: This *must* be called, otherwise states won't get initialized
  end

  def put_on_seatbelt
    @seatbelt_on = true
  end

  def passed_inspection?
    false
  end

  def tow
    # tow the vehicle
  end

  def fix
    # get the vehicle fixed by a mechanic
  end

  def log_start_failure
    # log a failed attempt to start the vehicle
  end
end
```

**Note** the comment made on the `initialize` method in the class.  In order for
state machine attributes to be properly initialized, `super()` must be called.
See `StateMachines:MacroMethods` for more information about this.

Using the above class as an example, you can interact with the state machine
like so:

```ruby
vehicle = Vehicle.new           # => #<Vehicle:0xb7cf4eac @state="parked", @seatbelt_on=false>
vehicle.state                   # => "parked"
vehicle.state_name              # => :parked
vehicle.human_state_name        # => "parked"
vehicle.parked?                 # => true
vehicle.can_ignite?             # => true
vehicle.ignite_transition       # => #<StateMachines:Transition attribute=:state event=:ignite from="parked" from_name=:parked to="idling" to_name=:idling>
vehicle.state_events            # => [:ignite]
vehicle.state_transitions       # => [#<StateMachines:Transition attribute=:state event=:ignite from="parked" from_name=:parked to="idling" to_name=:idling>]
vehicle.speed                   # => 0
vehicle.moving?                 # => false

vehicle.ignite                  # => true
vehicle.parked?                 # => false
vehicle.idling?                 # => true
vehicle.speed                   # => 10
vehicle                         # => #<Vehicle:0xb7cf4eac @state="idling", @seatbelt_on=true>

vehicle.shift_up                # => true
vehicle.speed                   # => 10
vehicle.moving?                 # => true
vehicle                         # => #<Vehicle:0xb7cf4eac @state="first_gear", @seatbelt_on=true>

# A generic event helper is available to fire without going through the event's instance method
vehicle.fire_state_event(:shift_up) # => true

# Call state-driven behavior that's undefined for the state raises a NoMethodError
vehicle.speed                   # => NoMethodError: super: no superclass method `speed' for #<Vehicle:0xb7cf4eac>
vehicle                         # => #<Vehicle:0xb7cf4eac @state="second_gear", @seatbelt_on=true>

# The bang (!) operator can raise exceptions if the event fails
vehicle.park!                   # => StateMachines:InvalidTransition: Cannot transition state via :park from :second_gear

# Generic state predicates can raise exceptions if the value does not exist
vehicle.state?(:parked)         # => false
vehicle.state?(:invalid)        # => IndexError: :invalid is an invalid name

# Namespaced machines have uniquely-generated methods
vehicle.alarm_state             # => 1
vehicle.alarm_state_name        # => :active

vehicle.can_disable_alarm?      # => true
vehicle.disable_alarm           # => true
vehicle.alarm_state             # => 0
vehicle.alarm_state_name        # => :off
vehicle.can_enable_alarm?       # => true

vehicle.alarm_off?              # => true
vehicle.alarm_active?           # => false

# Events can be fired in parallel
vehicle.fire_events(:shift_down, :enable_alarm) # => true
vehicle.state_name                              # => :first_gear
vehicle.alarm_state_name                        # => :active

vehicle.fire_events!(:ignite, :enable_alarm)    # => StateMachines:InvalidParallelTransition: Cannot run events in parallel: ignite, enable_alarm

# Human-friendly names can be accessed for states/events
Vehicle.human_state_name(:first_gear)               # => "first gear"
Vehicle.human_alarm_state_name(:active)             # => "active"

Vehicle.human_state_event_name(:shift_down)         # => "shift down"
Vehicle.human_alarm_state_event_name(:enable)       # => "enable"

# States / events can also be references by the string version of their name
Vehicle.human_state_name('first_gear')              # => "first gear"
Vehicle.human_state_event_name('shift_down')        # => "shift down"

# Available transition paths can be analyzed for an object
vehicle.state_paths                                       # => [[#<StateMachines:Transition ...], [#<StateMachines:Transition ...], ...]
vehicle.state_paths.to_states                             # => [:parked, :idling, :first_gear, :stalled, :second_gear, :third_gear]
vehicle.state_paths.events                                # => [:park, :ignite, :shift_up, :idle, :crash, :repair, :shift_down]

# Find all paths that start and end on certain states
vehicle.state_paths(:from => :parked, :to => :first_gear) # => [[
                                                          #       #<StateMachines:Transition attribute=:state event=:ignite from="parked" ...>,
                                                          #       #<StateMachines:Transition attribute=:state event=:shift_up from="idling" ...>
                                                          #    ]]
# Skipping state_machine and writing to attributes directly
vehicle.state = "parked"
vehicle.state                   # => "parked"
vehicle.state_name              # => :parked

# *Note* that the following is not supported (see StateMachines:MacroMethods#state_machine):
# vehicle.state = :parked
```

## Additional Topics

### Explicit vs. Implicit Event Transitions

Every event defined for a state machine generates an instance method on the
class that allows the event to be explicitly triggered.  Most of the examples in
the state_machine documentation use this technique.  However, with some types of
integrations, like ActiveRecord, you can also *implicitly* fire events by
setting a special attribute on the instance.

Suppose you're using the ActiveRecord integration and the following model is
defined:

```ruby
class Vehicle < ActiveRecord::Base
  state_machine initial: :parked do
    event :ignite do
      transition parked: :idling
    end
  end
end
```

To trigger the `ignite` event, you would typically call the `Vehicle#ignite`
method like so:

```ruby
vehicle = Vehicle.create    # => #<Vehicle id=1 state="parked">
vehicle.ignite              # => true
vehicle.state               # => "idling"
```

This is referred to as an *explicit* event transition.  The same behavior can
also be achieved *implicitly* by setting the state event attribute and invoking
the action associated with the state machine.  For example:

```ruby
vehicle = Vehicle.create        # => #<Vehicle id=1 state="parked">
vehicle.state_event = 'ignite'  # => 'ignite'
vehicle.save                    # => true
vehicle.state                   # => 'idling'
vehicle.state_event             # => nil
```

As you can see, the `ignite` event was automatically triggered when the `save`
action was called.  This is particularly useful if you want to allow users to
drive the state transitions from a web API.

See each integration's API documentation for more information on the implicit
approach.

### Symbols vs. Strings

In all of the examples used throughout the documentation, you'll notice that
states and events are almost always referenced as symbols.  This isn't a
requirement, but rather a suggested best practice.

You can very well define your state machine with Strings like so:

```ruby
class Vehicle
  state_machine initial: 'parked' do
    event 'ignite' do
      transition 'parked' => 'idling'
    end

    # ...
  end
end
```

You could even use numbers as your state / event names.  The **important** thing
to keep in mind is that the type being used for referencing states / events in
your machine definition must be **consistent**.  If you're using Symbols, then
all states / events must use Symbols.  Otherwise you'll encounter the following
error:

```ruby
class Vehicle
  state_machine do
    event :ignite do
      transition parked: 'idling'
    end
  end
end

# => ArgumentError: "idling" state defined as String, :parked defined as Symbol; all states must be consistent
```

There **is** an exception to this rule.  The consistency is only required within
the definition itself.  However, when the machine's helper methods are called
with input from external sources, such as a web form, state_machine will map
that input to a String / Symbol.  For example:

```ruby
class Vehicle
  state_machine initial: :parked do
    event :ignite do
      transition parked: :idling
    end
  end
end

v = Vehicle.new     # => #<Vehicle:0xb71da5f8 @state="parked">
v.state?('parked')  # => true
v.state?(:parked)   # => true
```

**Note** that none of this actually has to do with the type of the value that
gets stored.  By default, all state values are assumed to be string -- regardless
of whether the state names are symbols or strings.  If you want to store states
as symbols instead you'll have to be explicit about it:

```ruby
class Vehicle
  state_machine initial: :parked do
    event :ignite do
      transition parked: :idling
    end

    states.each do |state|
      self.state(state.name, :value => state.name.to_sym)
    end
  end
end

v = Vehicle.new     # => #<Vehicle:0xb71da5f8 @state=:parked>
v.state?('parked')  # => true
v.state?(:parked)   # => true
```

### Syntax flexibility

Although state_machine introduces a simplified syntax, it still remains
backwards compatible with previous versions and other state-related libraries by
providing some flexibility around how transitions are defined.  See below for an
overview of these syntaxes.

#### Verbose syntax

In general, it's recommended that state machines use the implicit syntax for
transitions.  However, you can be a little more explicit and verbose about
transitions by using the `:from`, `:except_from`, `:to`,
and `:except_to` options.

For example, transitions and callbacks can be defined like so:

```ruby
class Vehicle
  state_machine initial: :parked do
    before_transition from: :parked, except_to: :parked, do: :put_on_seatbelt
    after_transition to: :parked do |vehicle, transition|
      vehicle.seatbelt = 'off'
    end

    event :ignite do
      transition from: :parked, to: :idling
    end
  end
end
```

#### Transition context

Some flexibility is provided around the context in which transitions can be
defined.  In almost all examples throughout the documentation, transitions are
defined within the context of an event.  If you prefer to have state machines
defined in the context of a **state** either out of preference or in order to
easily migrate from a different library, you can do so as shown below:

```ruby
class Vehicle
  state_machine initial: :parked do
    ...

    state :parked do
      transition to: :idling, :on => [:ignite, :shift_up], if: :seatbelt_on?

      def speed
        0
      end
    end

    state :first_gear do
      transition to: :second_gear, on: :shift_up

      def speed
        10
      end
    end

    state :idling, :first_gear do
      transition to: :parked, on: :park
    end
  end
end
```

In the above example, there's no need to specify the `from` state for each
transition since it's inferred from the context.

You can also define transitions completely outside the context of a particular
state / event.  This may be useful in cases where you're building a state
machine from a data store instead of part of the class definition.  See the
example below:

```ruby
class Vehicle
  state_machine initial: :parked do
    ...

    transition parked: :idling, :on => [:ignite, :shift_up]
    transition first_gear: :second_gear, second_gear: :third_gear, on: :shift_up
    transition [:idling, :first_gear] => :parked, on: :park
    transition [:idling, :first_gear] => :parked, on: :park
    transition all - [:parked, :stalled]: :stalled, unless: :auto_shop_busy?
  end
end
```

Notice that in these alternative syntaxes:

* You can continue to configure `:if` and `:unless` conditions
* You can continue to define `from` states (when in the machine context) using
the `all`, `any`, and `same` helper methods

### Static / Dynamic definitions

In most cases, the definition of a state machine is **static**.  That is to say,
the states, events and possible transitions are known ahead of time even though
they may depend on data that's only known at runtime.  For example, certain
transitions may only be available depending on an attribute on that object it's
being run on.  All of the documentation in this library define static machines
like so:

```ruby
class Vehicle
  state_machine :state, initial: :parked do
    event :park do
      transition [:idling, :first_gear] => :parked
    end

    ...
  end
end
```

However, there may be cases where the definition of a state machine is **dynamic**.
This means that you don't know the possible states or events for a machine until
runtime.  For example, you may allow users in your application to manage the
state machine of a project or task in your system.  This means that the list of
transitions (and their associated states / events) could be stored externally,
such as in a database.  In a case like this, you can define dynamically-generated
state machines like so:

```ruby
class Vehicle
  attr_accessor :state

  # Make sure the machine gets initialized so the initial state gets set properly
  def initialize(*)
    super
    machine
  end

  # Replace this with an external source (like a db)
  def transitions
    [
      {parked: :idling, on: :ignite},
      {idling: :first_gear, first_gear: :second_gear, on: :shift_up}
      # ...
    ]
  end

  # Create a state machine for this vehicle instance dynamically based on the
  # transitions defined from the source above
  def machine
    vehicle = self
    @machine ||= Machine.new(vehicle, initial: :parked, action: :save) do
      vehicle.transitions.each {|attrs| transition(attrs)}
    end
  end

  def save
    # Save the state change...
    true
  end
end

# Generic class for building machines
class Machine
  def self.new(object, *args, &block)
    machine_class = Class.new
    machine = machine_class.state_machine(*args, &block)
    attribute = machine.attribute
    action = machine.action

    # Delegate attributes
    machine_class.class_eval do
      define_method(:definition) { machine }
      define_method(attribute) { object.send(attribute) }
      define_method("#{attribute}=") {|value| object.send("#{attribute}=", value) }
      define_method(action) { object.send(action) } if action
    end

    machine_class.new
  end
end

vehicle = Vehicle.new                   # => #<Vehicle:0xb708412c @state="parked" ...>
vehicle.state                           # => "parked"
vehicle.machine.ignite                  # => true
vehicle.machine.state                   # => "idling
vehicle.state                           # => "idling"
vehicle.machine.state_transitions       # => [#<StateMachines:Transition ...>]
vehicle.machine.definition.states.keys  # => :first_gear, :second_gear, :parked, :idling
```

As you can see, state_machine provides enough flexibility for you to be able
to create new machine definitions on the fly based on an external source of
transitions.

## Dependencies

Ruby versions officially supported and tested:

* Ruby (MRI) 2.0.0+
* JRuby
* Rubinius

For graphing state machine:

* [state_machines-graphviz](http://github.com/state-machines/state_machines-graphviz)

For documenting state machines:

* [state_machines-yard](http://github.com/state-machines/state_machines-yard)


## TODO

* Add matchers/assertions for rspec and minitest

## Contributing

1. Fork it ( https://github.com/state-machines/state_machines/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
