require_relative './base'

class StoreAsInt::Money < StoreAsInt::Base
  BASE = 100
  DECIMALS = 2
  SYM = '$'
end
