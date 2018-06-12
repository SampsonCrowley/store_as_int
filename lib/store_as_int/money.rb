module StoreAsInt
  unless defined?(StoreAsInt::Base)
    require_relative './base'
  end

  class Money < StoreAsInt::Base
    require 'bigdecimal'
    require 'bigdecimal/util'

    # == Constants ============================================================
    ACCURACY = 2
    DECIMALS = 2
    SYM = '$'

    # == Attributes ============================================================

    # == Extensions ===========================================================

    # == Class Methods ========================================================
    def self.extend_numerics
      Numeric.include StoreAsInt::ActsAsMoneyInt
    end
    # == Boolean Methods ======================================================

    # == Comparison Methods ===================================================

    # == Instance Methods =====================================================
    def dollar_str
      to_s(true)
    end

    def to_cents
      self
    end
  end

  module ActsAsMoneyInt
    def dollar_str
      to_cents.to_s(true)
    end

    def to_cents
      StoreAsInt::Money.new self
    end
  end
end
