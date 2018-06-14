$allow_numeric_stubbing = false
module StubNumeric
  def singleton_method_added(*args)
    super(*args) unless $allow_numeric_stubbing
  end
end

class Numeric
  prepend StubNumeric
end
