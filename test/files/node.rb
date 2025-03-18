# frozen_string_literal: true

class Node < Struct.new(:name, :value, :machine)
  def context
    yield
  end
end
