module StoreAsInt
  class Base
    require 'bigdecimal'
    require 'bigdecimal/util'

    # == Constants ============================================================
    BASE = 1
    DECIMALS = nil
    SYM = 1
    STR_FORMAT = nil

    # == Attributes ============================================================
    attr_accessor :num

    # == Extensions ===========================================================
    include Comparable

    # == Class Methods ========================================================
    def self.===(other)
      self === other || Integer === other
    end

    def self.<=>(other)
      self <=> other || Integer <=> other
    end

    def self.base
      self::BASE || 1
    end

    def self.decimals
      self::DECIMALS
    end

    def self.sym
      self::SYM || ''
    end

    def self.str_format
      self::STR_FORMAT
    end

    # == Instance Methods =====================================================
    def initialize(new_val = nil)
      return self.num = 0 unless new_val

      if new_val.is_a?(self.class)
        self.num = new_val.value
      elsif new_val.is_a?(Integer)
        self.num = new_val
      else
        self.num = (new_val.to_d * self.class.base).to_i
      end
    end

    def base
      self.class.base
    end

    def decimals
      @decimals ||= self.class.decimals
    end

    def base_float
      base.to_f
    end

    def sym
      @sym ||= self.class.sym
    end

    def sym=(new_sym)
      @sym = new_sym
    end

    def convert(other_val)
      self.class.new(other_val)
    end

    def <=>(compare)
      value <=> convert(compare).value
    end

    def == (compare)
      value == convert(compare).value
    end

    def kind_of?(klass)
      self.num.kind_of?(klass)
    end

    def to_i
      self.num.to_i
    end

    def to_f
      to_i/base_float
    end

    def to_d
      to_i.to_d/base
    end

    def cents
      self
    end

    def value
      self.num || 0
    end

    def as_json(*args)
      self.num.as_json(*args)
    end

    def inspect
      to_s(true)
    end

    def negative_sign
      value < 0 ? '-' : ''
    end

    def coerce(other)
      [other, value]
    end

    def to_s(w_sym = false)
      begin
        str_format.call(self, w_sym)
      rescue
        puts $!.message
        puts $!.backtrace
        ""
      end
    end

    def present?
      begin
        value.present?
      rescue NoMethodError
        !value.nil? && !(value.to_s == "")
      end
    end

    def method_missing(name, *args, &blk)
      ret = value.send(name, *args, &blk)
      ret.is_a?(Numeric) ? self.class.new(ret) : ret
    end

    private
      def str_format
        @str_format ||= self.class.str_format || ->(passed, w_sym) do
          return nil unless w_sym || passed.present?
          str = "#{passed.negative_sign}#{w_sym ? passed.sym : ''}#{passed.decimals ? sprintf("%0.0#{passed.decimals.to_i}f", passed.to_d.abs) : passed.to_i.to_s}".reverse.split('.')
          str[-1] = str[-1].gsub(/(\d{3})(?=\d)/, w_sym ? '\\1,' : '\\1')
          str.join('.').reverse
        end
      end
  end
end
