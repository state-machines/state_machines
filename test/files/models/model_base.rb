# frozen_string_literal: true

class ModelBase
  def save
    @saved = true
    self
  end
end
