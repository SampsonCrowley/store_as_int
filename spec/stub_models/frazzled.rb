class Frazzled
  def self.set(bool = false)
    @frazzled ||= bool
  end

  def self.get(*args)
    was_frazzled = !!@frazzled
    @frazzled = false
    was_frazzled
  end
end
