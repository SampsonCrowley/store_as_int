module StoreAsInt
  unless defined?(StoreAsInt::Base)
    require_relative './base'
  end

  class Money < StoreAsInt::Base
    BASE = 100
    DECIMALS = 2
    SYM = '$'
  end
end
