module EventOnFailureIntegration
  include StateMachines::Integrations::Base
  def invalidate(object, _attribute, message, values = [])
    (object.errors ||= []) << generate_message(message, values)
  end

  def reset(object)
    object.errors = []
  end
end