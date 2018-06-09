require_relative './base'

class StoreAsInt::Money < StoreAsInt::Base
  BASE = 100
  SYM = '$'
  DECIMALS = 2
end
