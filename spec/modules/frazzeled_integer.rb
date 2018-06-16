class Frazzled
  def self.set_frazzled(bool = false)
    @frazzled ||= bool
  end

  def self.get_frazzled(*args)
    was_frazzled = !!@frazzled
    @frazzled = false
    was_frazzled
  end
end

module Frazzle
  def frazzle(*passed)
    Frazzled.set_frazzled(true) if passed.any? {|arg| arg == :dazzle}
  end

  def dazzle
    Frazzled.get_frazzled
  end
end

class Integer
  include Frazzle
end
