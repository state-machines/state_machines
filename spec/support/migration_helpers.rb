# Remove this file when refactoring is done

def assert(obj)
  expect(obj).to be_truthy
end

def assert_equal(value, obj)
  expect(obj).to eq(value)
end

def assert_not_equal(value, obj)
  expect(obj).to_not eq(value)
end


def assert_not_nil(obj)
  expect(obj).to_not be_nil
end

def assert_nil(obj)
  expect(obj).to be_nil
end

def assert_raise(exception, &block)
  expect(block).to raise_error(exception)
end

def assert_nothing_thrown(&block)
  expect(block).to_not raise_error
end


def assert_nothing_raised(&block)
  expect(block).to_not raise_error
end


def assert_same(value, obj)
  expect(obj).to equal(value)
end

def assert_not_same(value, obj)
  expect(obj).to_not equal(value)
end

def assert_instance_of(klass, obj)
  expect(obj).to be_a klass
end

def assert_throws(symbol, &block)
  expect(block).to throw_symbol(symbol)
end

def assert_match(value, obj)
  expect(obj).to match(value)
end



