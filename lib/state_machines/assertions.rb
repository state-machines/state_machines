class Hash
  # Provides a set of helper methods for making assertions about the content
  # of various objects

  unless respond_to?(:assert_valid_keys)
    # Validate all keys in a hash match <tt>*valid_keys</tt>, raising ArgumentError
    # on a mismatch. Note that keys are NOT treated indifferently, meaning if you
    # use strings for keys but assert symbols as keys, this will fail.
    #
    #   { name: 'Rob', years: '28' }.assert_valid_keys(:name, :age) # => raises "ArgumentError: Unknown key: :years. Valid keys are: :name, :age"
    #   { name: 'Rob', age: '28' }.assert_valid_keys('name', 'age') # => raises "ArgumentError: Unknown key: :name. Valid keys are: 'name', 'age'"
    #   { name: 'Rob', age: '28' }.assert_valid_keys(:name, :age)   # => passes, raises nothing
    # Code from ActiveSupport
    def assert_valid_keys(*valid_keys)
      valid_keys.flatten!
      each_key do |k|
        unless valid_keys.include?(k)
          raise ArgumentError.new("Unknown key: #{k.inspect}. Valid keys are: #{valid_keys.map(&:inspect).join(', ')}")
        end
      end
    end
  end

  # Validates that the given hash only includes at *most* one of a set of
  # exclusive keys.  If more than one key is found, an ArgumentError will be
  # raised.
  #
  # == Examples
  #
  #   options = {:only => :on, :except => :off}
  #   options.assert_exclusive_keys(:only)                   # => nil
  #   options.assert_exclusive_keys(:except)                 # => nil
  #   options.assert_exclusive_keys(:only, :except)          # => ArgumentError: Conflicting keys: only, except
  #   options.assert_exclusive_keys(:only, :except, :with)   # => ArgumentError: Conflicting keys: only, except
  def assert_exclusive_keys(*exclusive_keys)
    conflicting_keys = exclusive_keys & keys
    raise ArgumentError, "Conflicting keys: #{conflicting_keys.join(', ')}" unless conflicting_keys.length <= 1
  end
end

