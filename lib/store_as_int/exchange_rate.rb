require_relative './base'

class StoreAsInt::ExchangeRate < StoreAsInt::Base
  BASE = 10000000000
  DECIMALS = 4
  SYM = '%'
end
