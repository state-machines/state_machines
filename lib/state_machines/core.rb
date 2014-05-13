# Load all of the core implementation required to use state_machine.  This
# includes:
# * StateMachines::MacroMethods which adds the state_machine DSL to your class
# * A set of initializers for setting state_machine defaults based on the current
#   running environment (such as within Rails)
require 'state_machines/assertions'
require 'state_machines/error'

require 'state_machines/extensions'

require 'state_machines/integrations'
require 'state_machines/integrations/base'

require 'state_machines/eval_helpers'

require 'singleton'
require 'state_machines/matcher'
require 'state_machines/matcher_helpers'

require 'state_machines/transition'
require 'state_machines/transition_collection'

require 'state_machines/branch'

require 'state_machines/helper_module'
require 'state_machines/state'
require 'state_machines/callback'
require 'state_machines/node_collection'

require 'state_machines/state_context'
require 'state_machines/state'
require 'state_machines/state_collection'

require 'state_machines/event'
require 'state_machines/event_collection'

require 'state_machines/path'
require 'state_machines/path_collection'

require 'state_machines/machine'
require 'state_machines/machine_collection'

require 'state_machines/macro_methods'