module StateMachines
  # An invalid integration was specified
  class IntegrationNotFound < Error
    def initialize(name)
      super(nil, "#{name.inspect} is an invalid integration")
    end
  end
  
  # Integrations allow state machines to take advantage of features within the
  # context of a particular library.  This is currently most useful with
  # database libraries.  For example, the various database integrations allow
  # state machines to hook into features like:
  # * Saving
  # * Transactions
  # * Observers
  # * Scopes
  # * Callbacks
  # * Validation errors
  # 
  # This type of integration allows the user to work with state machines in a
  # fashion similar to other object models in their application.
  # 
  # The integration interface is loosely defined by various unimplemented
  # methods in the StateMachines::Machine class.  See that class or the various
  # built-in integrations for more information about how to define additional
  # integrations.
  module Integrations
    # Attempts to find an integration that matches the given class.  This will
    # look through all of the built-in integrations under the StateMachines::Integrations
    # namespace and find one that successfully matches the class.
    # 
    # == Examples
    # 
    #   class Vehicle
    #   end
    #   
    #   class ActiveModelVehicle
    #     include ActiveModel::Observing
    #     include ActiveModel::Validations
    #   end
    #   
    #   class ActiveRecordVehicle < ActiveRecord::Base
    #   end
    #   
    #   class DataMapperVehicle
    #     include DataMapper::Resource
    #   end
    #   
    #   class MongoidVehicle
    #     include Mongoid::Document
    #   end
    #   
    #   class MongoMapperVehicle
    #     include MongoMapper::Document
    #   end
    #   
    #   class SequelVehicle < Sequel::Model
    #   end
    #   
    #   StateMachines::Integrations.match(Vehicle)             # => nil
    #   StateMachines::Integrations.match(ActiveModelVehicle)  # => StateMachines::Integrations::ActiveModel
    #   StateMachines::Integrations.match(ActiveRecordVehicle) # => StateMachines::Integrations::ActiveRecord
    #   StateMachines::Integrations.match(DataMapperVehicle)   # => StateMachines::Integrations::DataMapper
    #   StateMachines::Integrations.match(MongoidVehicle)      # => StateMachines::Integrations::Mongoid
    #   StateMachines::Integrations.match(MongoMapperVehicle)  # => StateMachines::Integrations::MongoMapper
    #   StateMachines::Integrations.match(SequelVehicle)       # => StateMachines::Integrations::Sequel
    def self.match(klass)
      all.detect {|integration| integration.matches?(klass)}
    end
    
    # Attempts to find an integration that matches the given list of ancestors.
    # This will look through all of the built-in integrations under the StateMachines::Integrations
    # namespace and find one that successfully matches one of the ancestors.
    # 
    # == Examples
    # 
    #   StateMachines::Integrations.match([])                    # => nil
    #   StateMachines::Integrations.match(['ActiveRecord::Base') # => StateMachines::Integrations::ActiveModel
    def self.match_ancestors(ancestors)
      all.detect {|integration| integration.matches_ancestors?(ancestors)}
    end
    
    # Finds an integration with the given name.  If the integration cannot be
    # found, then a NameError exception will be raised.
    # 
    # == Examples
    # 
    #   StateMachines::Integrations.find_by_name(:active_record) # => StateMachines::Integrations::ActiveRecord
    #   StateMachines::Integrations.find_by_name(:active_model)  # => StateMachines::Integrations::ActiveModel
    #   StateMachines::Integrations.find_by_name(:data_mapper)   # => StateMachines::Integrations::DataMapper
    #   StateMachines::Integrations.find_by_name(:mongoid)       # => StateMachines::Integrations::Mongoid
    #   StateMachines::Integrations.find_by_name(:mongo_mapper)  # => StateMachines::Integrations::MongoMapper
    #   StateMachines::Integrations.find_by_name(:sequel)        # => StateMachines::Integrations::Sequel
    #   StateMachines::Integrations.find_by_name(:invalid)       # => StateMachines::IntegrationNotFound: :invalid is an invalid integration
    def self.find_by_name(name)
      all.detect {|integration| integration.integration_name == name} || raise(IntegrationNotFound.new(name))
    end
    
    # Gets a list of all of the available integrations for use.  This will
    # always list the ActiveModel integration last.
    # 
    # == Example
    # 
    #   StateMachines::Integrations.all
    #   # => [StateMachines::Integrations::ActiveRecord, StateMachines::Integrations::DataMapper
    #   #     StateMachines::Integrations::Mongoid, StateMachines::Integrations::MongoMapper,
    #   #     StateMachines::Integrations::Sequel, StateMachines::Integrations::ActiveModel]
    def self.all
      constants = self.constants.map {|c| c.to_s}.select {|c| c }.sort
      constants.map {|c| const_get(c)}
    end
  end
end
