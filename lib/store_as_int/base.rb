module StoreAsInt
  class Base < Numeric
    require 'bigdecimal'
    require 'bigdecimal/util'

    # == Constants ============================================================
    ACCURACY ||= 5
    DECIMALS ||= 2
    SYM ||= nil
    STR_FORMAT ||= nil
    OPERATORS ||= [:+, :-, :*, :/, :%, :**].map {|sym| [sym]*2}.to_h

    # == Attributes ============================================================
    attr_accessor :num

    # == Extensions ===========================================================
    include Comparable

    # == Class Methods ========================================================
    def self.===(other)
      !!(
        Numeric === other ||
        (
          other.is_a?(Class) ?
          other :
          other.class
        ) <= self
      ) || !!(
        other.instance_of?(String) &&
        (
          other.gsub(/(,|\s)/, '') =~ matcher
        )
      )
    end

    def self.accuracy
      self::ACCURACY || 0
    end

    def self.base
      10 ** accuracy.to_i
    end

    def self.decimals
      self::DECIMALS
    end

    def self.hash_without_keys(h, keys, indifferent = false)
      n = h.dup
      if indifferent
        new_keys = keys.dup
        new_keys.each do |k|
          keys << k.to_sym
          keys << k.to_s
        end
        kys = keys.uniq
      end
      keys.each do |k|
        n.delete(k)
      end
      n
    end

    def self.json_create(o)
      if o.is_a?(Hash)
        n = {}
        for k, v in o
          n[k.to_sym] = v
        end
        created = new((n[:value] || n[:int] || n[:decimal] || n[:float] || n[:str]), (n[:sym] || nil))

        hash_without_keys(o, %w(decimal float int json_class str str_pretty value), true).each do |k, v|
          k = k.dup
          if created.respond_to?(k, true) || created.respond_to?(k.to_s.sub!('str_', ''))
            created.instance_variable_set("@#{k}", v)
          end
        end
        created
      else
        new(o)
      end
    end

    def self.matcher
      /^(\-|\+)?(?:#{sym.to_s.size > 0 ? Regexp.quote(sym.to_s) : '[^0-9]'}*)([0-9]+)(\.[0-9]+)?$/
    end

    def self.sym
      self::SYM
    end

    def self.str_format
      self::STR_FORMAT
    end

    def self.operators
      self::OPERATORS
    end

    # == Boolean Methods ======================================================
    def duplicable?
      true
    end

    def is_a?(klass)
      kind_of?(klass)
    end

    def is_an?(klass)
      kind_of?(klass)
    end

    def kind_of?(klass)
      value.kind_of?(klass) ||
      self.class == klass ||
      StoreAsInt == klass ||
      super(klass)
    end

    def instance_of?(klass)
      self.class == klass
    end

    def present?
      begin
        self.num.present?
      rescue NoMethodError
        !self.num.nil? && !(self.num.to_s == "")
      end
    end

    # == Comparison Methods ===================================================
    def <=>(compare)
      value <=> convert(compare).value
    end

    def ==(compare)
      value == convert(compare).value
    end

    def ===(compare)
      self.== compare
    end

    # == Instance Methods =====================================================
    def initialize(new_val = nil, new_sym = nil)
      self.sym = new_sym if new_sym

      return self.num = nil unless new_val && (new_val != '')

      if new_val.is_a?(self.class)
        self.num = new_val.value
      elsif new_val.is_a?(Integer)
        self.num = new_val
      else
        if new_val.is_a?(String)
          begin
            new_val =
              new_val.
              gsub(/(,|\s)/, '').
              match(self.class.matcher)[1..-1].join("")
          rescue NoMethodError
            return self.num = 0
          end
        end

        self.num = (new_val.to_d * self.class.base).to_i
      end
    end

    def accuracy
      @accuracy ||= self.class.accuracy || 0
    end

    def as_json(*args)
      to_h
    end

    def base
      @base ||= 10 ** accuracy
    end

    def base_float
      base.to_f
    end

    def coerce(other_val)
      [convert(other_val), self]
    end

    def convert(other_val)
      self.class.new(other_val, sym)
    end

    def decimals
      @decimals ||= self.class.decimals
    end

    def dup
      self.class.new self.num
    end

    def inspect
      to_s(true)
    end

    def matcher
      @matcher ||= self.class.matcher
    end

    def method_missing(name, *args, &blk)
      if self.operators[name.to_sym]
        if args[0].kind_of?(self.class)
          convert(value.__send__ name, args[0].value, *args[1..-1])
        else
          convert(value.__send__(name, convert(args[0]), *args[1..-1]))
        end
      else
        ret = value.send(name, *args, &blk)
        ret.is_a?(Numeric) ? convert(ret) : ret
      end
    end

    def negative_sign
      value < 0 ? '-' : ''
    end

    def operators
      @operators ||= self.class.operators.dup
    end

    def sym
      @sym ||= self.class.sym || ''
    end

    def sym=(new_sym = nil)
      @sym = new_sym ? new_sym.to_s : self.class.sym
    end

    def to_d
      to_i.to_d/base
    end

    def to_f
      to_i/base_float
    end

    def to_h
      {
        accuracy: accuracy,
        base: base,
        decimal: to_d,
        decimals: decimals,
        float: to_f,
        int: to_i,
        json_class: self.class,
        str: to_s,
        str_format: str_format,
        str_matcher: matcher,
        str_pretty: to_s(true),
        sym: sym,
        value: value,
      }
    end

    def to_i
      value.to_i
    end

    def to_json(*args)
      h = self.to_h
      h.delete(:str_format)
      begin
        h.to_json
      rescue NoMethodError
        require 'json'
        JSON.unparse(h)
      end
    end

    def to_s(w_sym = false, padding: 0)
      begin
        str_format.call(self, w_sym, padding)
      rescue
        puts $!.message
        puts $!.backtrace
        ""
      end
    end

    def value
      self.num || 0
    end

    private
      def str_format
        @str_format ||= self.class.str_format || ->(passed, w_sym, padding) do
          return '' unless w_sym || passed.present? || (padding.to_i > 0)
          prefix = "#{
            passed.negative_sign
          }#{
            w_sym ? passed.sym : ''
          }"
          str = "#{
            passed.decimals ?
            sprintf("%0.0#{passed.decimals.to_i}f", passed.to_d.abs) :
            passed.to_i.to_s
          }".reverse.split('.')

          str[-1] =
            str[-1].
            gsub(/(\d{3})(?=\d)/, w_sym ? '\\1,' : '\\1').
            ljust(padding.to_i, ' ')

          "#{prefix}#{str.join('.').reverse}"
        end
      end
  end
end
