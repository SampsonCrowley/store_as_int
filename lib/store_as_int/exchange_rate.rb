module StoreAsInt
  unless defined?(StoreAsInt::Base)
    require_relative './base'
  end

  class ExchangeRate < StoreAsInt::Base
    require 'bigdecimal'
    require 'bigdecimal/util'

    # == Constants ============================================================
    ACCURACY = 10
    DECIMALS = 4
    SYM = '%'

    # == Attributes ============================================================

    # == Extensions ===========================================================

    # == Class Methods ========================================================
    def self.extend_numerics
      Numeric.include StoreAsInt::ActsAsExchangeRateInt
    end

    # == Boolean Methods ======================================================

    # == Comparison Methods ===================================================

    # == Instance Methods =====================================================
    def exchange_rate_str
      to_s(true)
    end

    def to_exchange_rate
      self
    end
  end

  module ActsAsExchangeRateInt
    def exchange_rate_str
      to_exchange_rate.to_s(true)
    end

    def to_exchange_rate
      StoreAsInt::ExchangeRate.new self
    end
  end
end
