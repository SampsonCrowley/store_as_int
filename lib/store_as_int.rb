# = StoreAsInt
#
#   Seamlessly Store Decimal Values as Integers!
module StoreAsInt

  if defined?(Rails)
    require 'store_as_int/engine'
  else
    require 'store_as_int/exchange_rate'
    require 'store_as_int/money'
  end

  # Create a new ::ExchangRate
  #
  # === Args
  # val:: value to use with the exchange rate
  #
  # === Examples
  #   er = StoreAsInt.exchange_rate(1.234567890)
  #       OR
  #   er = StoreAsInt.exchange_rate('1.234567890')
  #       OR
  #   er = StoreAsInt.exchange_rate(1234567890)
  #
  #   er.to_s => '1.2345'
  #   er.to_s(true) => '%1.2345'
  #   er.inspect => '%1.2345'
  #   er.to_d => 1.234567890
  #   er.value => 1234567890
  #
  def self.exchange_rate(val)
    ExchangeRate.new(val)
  end

  # Create a new ::Money
  #
  # === Args
  # val:: value to use with the money
  #
  # === Examples
  #   er = StoreAsInt.money(1001.23)
  #       OR
  #   er = StoreAsInt.money("1001.23")
  #       OR
  #   er = StoreAsInt.money(100123)
  #
  #   er.to_s => '1001.23'
  #   er.to_s(true) => '$1,001.23'
  #   er.inspect => '$1,001.23'
  #   er.to_d => 1001.23
  #   er.value => 100123
  #
  def self.money(val)
    Money.new(val)
  end

  # Register a new StoreAsInt type
  #
  # === Args
  # under_scored_class_name:: @string - method name to use when initializing
  # base_value:: @integer - number to multiply and divide by when doing conversions
  # number_of_decimals:: @integer - number of decimals to include in to_s method
  # symbol_to_use:: @string - symbol to use in to_s method
  # &block::
  #   @block - override to_s method with a block.
  #   called with arguments (self, w_sym)
  #   where w_sym is a boolean for whether to include symbol in the returned string
  #
  # === Examples
  #   StoreAsInt.register 'accurate_money', 10000, 2, '$'
  #
  #   am = StoreAsInt::AccurateMoney.new(1.2345)
  #   am.to_s(true) => $1.23
  #   am.value => 12345
  #
  # ----------
  #
  #   StoreAsInt.register 'custom_to_s', 100, 2, '$' do |passed, w_sym|
  #     "CUSTOM_STR #{passed.negative_sign}#{passed.sym}#{sprintf("%0.0#{passed.decimals}f", passed.to_d.abs)}"
  #   end
  #
  #   cts = StoreAsInt.custom_to_s(-1.23)
  #   cts.to_s(true) => CUSTOM_STR -$1.23
  #   cts.to_s => CUSTOM_STR -$1.23
  #   cts.value => -123
  #
  def self.register(under_scored_class_name, base_value = 1, number_of_decimals = 0, symbol_to_use = '', &block)
    const_name = under_scored_class_name.split('_').map(&:capitalize).join('')

    begin
      const_get(const_name)

      puts "WARNING - #{const_name} Already Registered. Nothing has been done"
    rescue NameError
      puts "  - Registering StoreAsInt::#{const_name}"

      const_set const_name, Class.new(StoreAsInt::Base)

      puts "  - Registering local constants for StoreAsInt::#{const_name}"

      const_get(const_name).const_set 'BASE', (base_value && base_value.to_i) || 1
      const_get(const_name).const_set 'DECIMALS', number_of_decimals.to_i
      const_get(const_name).const_set 'SYM', symbol_to_use.to_s
      const_get(const_name).const_set 'STR_FORMAT', block || nil

      puts "  - Registering shortcut method: StoreAsInt.#{under_scored_class_name}(value)"

      define_singleton_method under_scored_class_name.to_sym do |val|
        const_get(const_name).new(val)
      end

      puts "  - StoreAsInt::#{const_name} registered"
    end

    const_get(const_name)
  end
end
