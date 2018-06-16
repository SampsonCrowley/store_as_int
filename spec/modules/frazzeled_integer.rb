require_relative '../stub_models/frazzled'
class IntegerFrazzler < Frazzled
end

module Frazzle
  def frazzle(*passed)
    IntegerFrazzler.set(true) if passed.any? {|arg| arg == :dazzle}
  end

  def dazzle
    IntegerFrazzler.get
  end
end

class Integer
  include Frazzle
end
