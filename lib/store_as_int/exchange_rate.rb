module StoreAsInt
  unless defined?(StoreAsInt::Base)
    require_relative './base'
  end
  
  class ExchangeRate < StoreAsInt::Base
    BASE = 10000000000
    DECIMALS = 4
    SYM = '%'
  end
end
