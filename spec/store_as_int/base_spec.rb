require_relative '../spec_helper'
require_relative '../../lib/store_as_int/base'

default_constants = [
  ['ACCURACY', 5],
  ['DECIMALS', 2],
  ['SYM', nil],
  ['STR_FORMAT', nil],
  ['OPERATORS', [:+, :-, :*, :/, :%, :**].map {|sym| [sym]*2}.to_h]
]
class InheritedFromBase < StoreAsInt::Base
  ACCURACY = 3
  DECIMALS = 3
  SYM = '#'
  STR_FORMAT = ->{}
  OPERATORS = {}
end

describe StoreAsInt::Base do
  before(:each) { IntegerFrazzler.set false }

  subject { StoreAsInt::Base }
  let(:inherited) { InheritedFromBase }
  let(:fifteen) { StoreAsInt::Base.new(15.00) }
  let(:alt_sym) { StoreAsInt::Base.new(15.00, '#') }
  let(:zero) { StoreAsInt::Base.new }

  describe 'Constants' do
    default_constants.each do |constant, value|
      it "should default ::#{constant} to '#{value || (value.nil? ? 'nil' : 'false')}'" do
        expect(subject.const_get constant).to eq value
      end
    end
  end

  describe 'Singleton Methods' do
    describe :=== do
      it 'should accept all numeric values' do
        [1, 2.5, BigDecimal.new(1)].each do |val|
          expect(subject === val).to be true
        end
      end

      it 'should accept numeric strings' do
        expect(subject === '2.34').to be true
        expect(subject === '+2.34').to be true
        expect(subject === '-2.34').to be true
        expect(subject === 'ASFD').to be false
        expect(subject === '2.3.4').to be false
      end

      it "should also return true for it's own subclasses" do
        expect(subject === inherited).to be true
        expect(inherited === subject).to be false
      end
    end

    describe :json_create do
      let(:alt_options) do
        {
          accuracy: 15,
          base: 10 ** 15,
          decimals: 5,
          value: 200,
          str_format: ->(passed, w_sym) do
            return 'asdf' unless w_sym
            return 'AYYYY'
          end
        }
      end
      let(:alt_b_and_a) { StoreAsInt::Base.json_create(alt_options) }
      let(:from_h) { StoreAsInt::Base.json_create(alt_sym.to_h) }

      it 'should reparse to_h' do
        require 'json'
        expect(from_h).to respond_to :value
        expect(from_h.value).to eq alt_sym.value
        expect(from_h.sym).to eq alt_sym.sym
        expect(from_h.sym).to_not eq fifteen.sym
        expect(from_h.to_s(true)).to eq alt_sym.to_s(true)
        expect(from_h.to_s(true)).to_not eq fifteen.to_s(true)

        alt_options.each {|k, v| expect(alt_b_and_a.to_h[k]).to eq alt_options[k]}

        expect(alt_b_and_a.to_s).to eq 'asdf'
        expect(alt_b_and_a.to_s(true)).to eq 'AYYYY'
      end

      it 'should recreate a new store as int from to_json' do
        expect(JSON.parse(alt_sym.to_json, create_additions: true)).to respond_to :value
        expect(JSON.parse(alt_sym.to_json, create_additions: true).value).to eq alt_sym.value
        expect(JSON.parse(alt_sym.to_json, create_additions: true).sym).to eq alt_sym.sym
        expect(JSON.parse(alt_sym.to_json, create_additions: true).sym).to_not eq fifteen.sym
        expect(JSON.parse(alt_sym.to_json, create_additions: true).to_s(true)).to eq alt_sym.to_s(true)
        expect(JSON.parse(alt_sym.to_json, create_additions: true).to_s(true)).to_not eq fifteen.to_s(true)
        expect(JSON.parse(alt_b_and_a.to_json, create_additions: true).accuracy).to eq alt_b_and_a.accuracy
        expect(JSON.parse(alt_b_and_a.to_json, create_additions: true).base).to eq alt_b_and_a.base
        expect(JSON.parse(alt_b_and_a.to_json, create_additions: true).decimals).to eq alt_b_and_a.decimals
        expect(JSON.parse(alt_b_and_a.to_json, create_additions: true).to_s).to_not eq 'asdf'
        expect(JSON.parse(alt_b_and_a.to_json, create_additions: true).to_s(true)).to_not eq 'AYYYY'
      end
    end

    describe 'Constant Accessors' do
      default_constants.each do |constant, value|
        it "should exist for ::#{constant}" do
          expect(subject).to respond_to(constant.downcase.to_sym)
          expect{subject.__send__(constant.downcase.to_sym)}.to_not raise_error

          expect(subject.__send__ constant.downcase).to eq subject.const_get constant
        end

        it "should scope inherited #{constant} accessor to that class" do

          expect(inherited.base).to eq 1000

          default_constants.each do |constant, value|
            expect(inherited.__send__ constant.downcase).to_not eq subject.__send__ constant.downcase
            expect(inherited.__send__ constant.downcase).to_not eq subject.__send__ constant.downcase
            expect(subject.base)
            expect(inherited.decimals).to eq 3
          end
        end
      end
    end
  end

  describe 'Instance Methods' do
    describe '#initialize' do
      context 'no arguments' do
        it 'defaults to 0' do
          expect(subject.new.value).to eq 0
        end
      end

      describe "Arg 1" do
        context 'real numbers (Floats and Decimals)' do
          it 'keeps the whole number section and coerces to ::Base accuracy' do
            accuracy = subject.accuracy || 0
            [
              [1.0, 10 ** accuracy],
              [1.to_f, 10 ** accuracy],
              [-1.to_f, -(10 ** accuracy)],
              [0.1234, 12340],
              [0.123456789, 12345],
              [1234.to_f, 1234 * (10 ** accuracy)],
              [BigDecimal.new(0.1234567890, 10), 12345],
            ].each do |raw, converted|
              str = raw.to_s
              int, decimals = str.split(".")
              val = subject.new(raw).value
              start = nil

              expect(val).to eq(converted)

              if int == '0'
                expect(val.to_s).to_not match Regexp.new("^#{int}.*?")
                start = ""
              else
                expect(val.to_s).to match Regexp.new("^#{int}.*?")
                start = int
              end

              length = [decimals.size, accuracy].min - 1
              expected_val = "#{start}#{decimals[0..length]}#{(decimals.size < accuracy) ? ('0' * (accuracy - decimals.size)) : ''}"
              expect(val.to_s).to match Regexp.new("^#{expected_val}")
              expect(val).to eq(expected_val.to_i)
            end
          end
        end

        context "whole numbers (Integers)" do
          it "directly stores value" do
            (1..10000).each do |i|
              expect(subject.new(i).value).to eq i
            end

            expect(subject.new(10 ** subject.accuracy).to_s).to eq '1.00'

            (1..10).each do |i|
              front = i < 5 ? '0' : ('1' + (i > 5 ? '0' * (i - 5) : ''))
              back = ((i == 3) && '01') || ((i == 4) && '10') || '00'
              expect(subject.new(10 ** i).to_s).to eq "#{front}.#{back}"
            end
          end
        end

        context 'strings' do
          context "valid pattern" do
            it "cooerces to base accuracy" do
              [
                ['1.0', (10 ** subject.accuracy)],
                ['1', (10 ** subject.accuracy)],
                ['$1.00', (10 ** subject.accuracy)],
                ['$0.12345', (12345)],
                ['#0.12345', (12345)],
                ['#26', (2600000)],
                ['0.12345', (12345)],
                ['asaa0.12345', (12345)],
              ].each do |str, val|
                expect(subject.new(str).value).to eq val
                expect(subject.new("+#{str}").value).to eq val
                expect(subject.new("-#{str}").value).to eq -val
              end
            end
          end

          context "invalid pattern" do
            it 'sets to 0' do
              expect(subject.new('ASDF').value).to eq 0
              expect(subject.new('1.0.0').value).to eq 0
            end
          end
        end
      end

      describe "Arg 2" do
        context "truthy" do
          it "sets sym as a string" do
            expect(subject.new(0, "1").sym).to eq "1"
            expect(subject.new(0, 1).sym).to eq "1"
          end
        end

        context "falsey" do
          it "keeps the default sym" do
            default_sym = StoreAsInt::Base.sym || ''
            expect(subject.new(0).sym).to eq default_sym
            expect(subject.new(0, nil).sym).to eq default_sym
            expect(subject.new(0, false).sym).to eq default_sym
          end
        end
      end
    end

    describe 'Abstracts' do
      subject { StoreAsInt::Base.new 12345 }

      context 'Duplication' do
        it 'should be duplicable' do
          expect(subject).to respond_to :dup
          expect{ subject }.to_not raise_error

          val = subject.value
          dupped = subject.dup

          expect(subject.dup.value).to eq val
          expect(dupped).to_not be subject

          dupped += 5000

          expect(subject).to eq val
          expect(dupped).to_not eq val
        end
      end
    end

    describe 'Comparison Methods' do
      describe '<=>' do
        it 'initializes the "other" value then compares values' do
          expect(-1 <=> zero).to be -1
          expect(0 <=> zero).to be 0
          expect(1 <=> zero).to be 1

          expect(fifteen <=> 14.0).to be 1
          expect(14.0 <=> fifteen).to be -1
          expect(fifteen <=> 15.0).to be 0
          expect(15.0 <=> fifteen).to be 0
          expect(fifteen <=> 16.0).to be -1
          expect(16.0 <=> fifteen).to be 1
        end
      end

      describe '==' do
        it 'initializes the "other" value then compares values' do
          expect(-1 == zero).to be false
          expect(0 == zero).to be true
          expect(0.0 == zero).to be true

          expect((15 * (10 ** subject.accuracy)) == fifteen).to be true
          expect(fifteen == (15 * (10 ** subject.accuracy))).to be true
          expect(15.0 == fifteen).to be true
          expect(fifteen == 15.0).to be true
          expect(BigDecimal.new(15, 5) == fifteen).to be true
          expect(fifteen == BigDecimal.new(15, 5)).to be true

          expect(fifteen == 14.0).to be false
          expect(14.0 == fifteen).to be false
          expect(fifteen == 16.0).to be false
          expect(16.0 == fifteen).to be false
        end
      end

      describe '===' do
        it 'is an alias for "=="' do
          expect([zero, :===]).to be_an_alias_of(:==).with(0)
        end
      end
    end

    describe 'Boolean Methods' do
      subject { StoreAsInt::Base.new }

      describe 'duplicable?' do
        it 'should be defined' do
          expect(subject).to respond_to :duplicable?
          expect{ subject.dup }.to_not raise_error
        end

        it 'should return true' do
          expect(subject.duplicable?).to eq true
        end
      end

      %w(
        is_a?
        is_an?
      ).each do |str|
        describe str do
          it 'should be defined' do
            expect(subject).to respond_to str.to_sym
            expect{ subject.__send__(str.to_sym, subject.class) }.to_not raise_error
          end

          it 'is an alias for "kind_of?"' do
            expect([subject, str.to_sym]).to be_an_alias_of(:kind_of?).with(Class)
          end
        end
      end

      describe 'kind_of?' do
        it 'should be defined' do
          expect(subject).to respond_to :kind_of?
          expect{ subject.kind_of? Class }.to_not raise_error

        end

        [
          Integer,
          Numeric,
          StoreAsInt
        ].each do |klass|
          context klass do
            it 'returns true' do
              expect(subject.is_a? klass).to eq true
            end
          end
        end

        context 'self' do
          it 'returns true' do
          end
        end

        context 'class chain' do
          it 'returns true' do
            klass = subject.class
            while klass.class != Class do
              expect(subject.is_a? klass).to eq true
              klass = klass.class
            end
          end
        end

        context 'invalid class chain' do
          it 'returns false' do
            require_relative '../../lib/store_as_int/money'
            expect(subject.is_a? StoreAsInt::Money).to eq false
            expect(subject.is_a? String).to eq false
          end
        end
      end

      describe 'instance_of?' do
        context "own class" do
          it 'returns true' do
            expect(subject.instance_of? subject.class).to eq true
          end
        end
        context 'anything else' do
          it 'returns false' do
            expect(subject.instance_of? Integer).to eq false
          end
        end
      end

      describe 'present?' do
        context 'nil' do
          it "should return false" do
            expect(StoreAsInt::Base.new.present?).to eq false
          end
        end

        context 'empty string' do
          it "should return false" do
            expect(StoreAsInt::Base.new('').present?).to eq false
          end
        end

        context 'numeric' do
          it "should return true" do
            [0, 0.0, 1.to_f, -1, BigDecimal.new(0.1234567890, 10)].each do |val|
              expect(StoreAsInt::Base.new(val).present?).to eq true
            end
          end
        end

      end
    end

    describe 'Value Methods' do
      subject { StoreAsInt::Base.new }

      describe "accuracy" do
        it_behaves_like "a class method instance", :accuracy
      end

      describe "as_json" do
        it "is an alias for to_h" do
          expect([subject, :as_json]).to be_an_alias_of(:to_h)
        end
      end

      describe "base" do
        it_behaves_like "a class method instance", :base
      end

      describe "base_float" do
        it "is the floated value of base" do
          expect(subject.base_float).to eq subject.base.to_f
        end
      end

      describe "coerce" do
        let(:coerced) { subject.coerce 123 }
        it "should return an array of the current class" do
          expect(coerced).to be_an Array
          expect(coerced).to all be_a(subject.class)
        end

        it "should put the cooerced value at the first index" do
          expect(coerced.first).to_not be subject
          expect(coerced.first).to_not eq subject
          expect(coerced.first.value).to eq 123
        end

        it "should put self second" do
          expect(coerced[1]).to be subject
          expect(coerced[1]).to eq subject
        end

        it "should use convert to coerce the value" do
          dupped = subject.dup
          convert_method_was_called = false
          $allow_numeric_stubbing = true
          allow(dupped).to receive(:convert).with(123) { convert_method_was_called = true }
          $allow_numeric_stubbing = false

          dupped.coerce 123

          expect(convert_method_was_called).to eq true
        end

      end

      describe "convert" do
        let(:converted) { subject.convert(123)}

        it "initializes a new instance with the passed value" do
          expect(converted).to be_a subject.class
          expect(converted).to_not be subject.class

          without_partial_double_verification do
            dupped = subject.dup
            method_was_called = false
            $allow_numeric_stubbing = true
            allow(dupped).to receive(:new).with(123) { method_was_called = true }
            $allow_numeric_stubbing = false
            dupped.convert 123
          end
        end

        it "retains the current symbol" do
          basis = StoreAsInt::Base.new nil, '@'
          converted_w_sym = basis.convert(123)
          expect(converted_w_sym.sym).to eq '@'
        end
      end

      describe "decimals" do
        it_behaves_like "a class method instance", :decimals
      end

      describe "inspect" do
        it "is a shortcut for 'to_s(true)'" do
          expect([zero, :inspect]).to be_a_shortcut_for(:to_s).with(true)
        end
      end

      describe "matcher" do
        it_behaves_like "a class method instance", :matcher
      end

      describe "method_missing" do
        subject { StoreAsInt::Base.new 1 }

        before :context do
          $allow_numeric_stubbing = true
        end
        after :context do
          $allow_numeric_stubbing = false
        end

        let(:stubbed_convert) do
          dupped = subject.dup
          @method_missing_stubbed_convert_was_called = false
          allow(dupped).to receive(:convert) do |*args|
            @method_missing_stubbed_convert_was_called = true
            subject.convert(*args)
          end
          dupped
        end

        context "class operators" do
          it "converts submitted value, then does integer math" do
            subject.operators.each do |_, operator|
              @method_missing_stubbed_convert_was_called = false
              value = stubbed_convert.__send__(operator, 123)
              expect(@method_missing_stubbed_convert_was_called).to eq true
              expect(value).to eq(stubbed_convert.value.__send__(operator, 123))
            end
          end

          it "directionally equivalent" do
            one = subject.class.new 1
            floated = subject.class.new 1.0

            expect(1 + subject).to eq subject + 1
            expect(1.0 + subject).to eq subject + 1.0
            expect(1.0 + floated).to eq floated + 1.0
            expect(1.0 + floated).to eq floated.class.new 2.0
            expect(floated + 1.0).to eq floated.class.new 2.0

            subject.operators.each do |_, operator|
              expect(1.__send__(operator, one)).to eq one.__send__(operator, 1)
              expect(1.__send__(operator, one).to_i).to eq one.__send__(operator, 1).to_i
              expect(1.0.__send__(operator, floated)).to eq floated.__send__(operator, 1.0)
              expect(1.0.__send__(operator, floated).to_i).to eq floated.__send__(operator, 1.0).to_i
              if [:/, :%].include? operator
                expect { zero.__send__(operator, 0) }.to raise_error ZeroDivisionError
                expect { 0.__send__(operator, zero) }.to raise_error ZeroDivisionError
              else
                expect(0.__send__(operator, zero)).to eq zero.__send__(operator, 0)
                expect(0.__send__(operator, zero).to_i).to eq zero.__send__(operator, 0).to_i
              end
            end
          end
        end

        context "everything else" do
          context "valid integer method" do
            it "delegates to 'value'" do
              @method_missing_stubbed_convert_was_called = false

              expect(stubbed_convert.dazzle).to eq false
              stubbed_convert.frazzle :dazzle
              expect(@method_missing_stubbed_convert_was_called).to eq false
              expect(stubbed_convert.dazzle).to eq true
              expect(stubbed_convert.dazzle).to eq false
            end
          end

          context "no method" do
            it "throws a NoMethodError" do
              expect { stubbed_convert.asdf }.to raise_error NoMethodError
            end
          end
        end
      end

      describe "negative_sign" do
        subject { StoreAsInt::Base.new 1 }
        let(:negative) { -subject }
        it "works" do
          expect(subject).to respond_to :negative_sign
          expect{negative.negative_sign}.to_not raise_error
        end
        context "negative value" do
          it "returns a negative symbol" do
            expect(negative.negative_sign).to eq '-'
          end
        end

        context "positive value" do
          it "returns an empty string" do
            expect(subject.negative_sign).to eq ''
          end
        end
      end

      describe "operators" do
        it_behaves_like "a class method instance", :operators
      end

      describe "sym" do
        it_behaves_like "a class method instance", :sym, '', true
      end

      describe "sym=" do
        context "truthy" do
          it "sets the instance variable @sym" do
            subject.sym = "$"
            expect(subject.sym).to eq '$'
            subject.sym = "#"
            expect(subject.sym).to_not eq '$'
            expect(subject.sym).to eq '#'
            subject.sym = "false"
            expect(subject.sym).to eq 'false'
            subject.sym = true
            expect(subject.sym).to eq 'true'
          end
        end

        context "falsey" do
          it "sets sym back to default" do
            default_sym = StoreAsInt::Base.sym
            dupped = subject.dup
            [
              [],
              [nil],
              [false]
            ].each do |args|
              dupped.sym = "$"
              expect(dupped.sym).to eq '$'

              expect(dupped.__send__(:sym=, *args)).to eq default_sym
              expect(dupped.instance_variable_get :@sym).to eq default_sym
              expect(dupped.sym).to eq default_sym.to_s
            end
          end
        end
      end

      describe "to_d" do
        it "should return the BigDecimal value" do
          bd = BigDecimal.new(1.0, subject.accuracy)
          expect(StoreAsInt::Base.new(bd).to_d).to eq bd
        end
      end

      describe "to_f" do
        it "should return the floated value" do
          expect(StoreAsInt::Base.new(1.0).to_f).to be 1.0
        end
      end

      describe "to_h" do
        subject { StoreAsInt::Base.new(1.0) }
        it "should return a hash" do
          expect(subject.to_h).to be_a Hash
        end

        it "details the current state" do
          val = subject.to_h
          {
            accuracy: :accuracy,
            base: :base,
            decimal: :to_d,
            decimals: :decimals,
            float: :to_f,
            str: :to_s,
            str_format: :str_format,
            str_matcher: :matcher,
            str_pretty: :inspect,
            sym: :sym,
            value: :value,
          }.each do |key, method|
            expect(val).to have_key(key)

            expect(subject.__send__ method).to eq val[key]
          end
        end
      end

      describe "to_i" do
        it "returns an integer value" do
          expect(subject.to_i).to be_an Integer
        end

        it 'is a shortcut for "value.to_i"' do
          expect(subject.to_i).to eq subject.value.to_i
        end
      end

      describe "to_json" do
        it "returns a json string of 'to_h' except for str_formatter" do
          hashed = subject.to_h
          hashed.delete(:str_format)
          json = nil
          begin
            json = hashed.to_json
          rescue NoMethodError
            require 'json'
            json = JSON.unparse(hashed)
          end
          expect(subject.to_json.to_s).to eq json.to_s
        end
      end

      describe "to_s" do
        let(:present_with_symbol) do
          w_sym = StoreAsInt::Base.new 1.0
          w_sym.sym = '@'
          w_sym
        end

        let(:blank_with_symbol) do
          w_sym = StoreAsInt::Base.new
          w_sym.sym = '@'
          w_sym
        end

        let(:symbol_false) { with_symb }
        context "present?" do
          context "arg: falsey (default)" do
            it "returns a string without 'sym'" do
              [
                [],
                [false],
                [nil]
              ].each do |args|
                expect(present_with_symbol.to_s(*args)).to_not match /#{Regexp.quote(present_with_symbol.sym)}/
                expect(present_with_symbol.to_s(*args)).to match /^\d+\.\d{#{present_with_symbol.decimals}}$/
              end
            end
          end

          context "arg: truthy" do
            it "returns a fully formatted string" do
              expect(present_with_symbol.to_s(true)).to match /^#{Regexp.quote(present_with_symbol.sym)}\d+\.\d{#{present_with_symbol.decimals}}$/
            end
          end

          context 'positive' do
            it "should not have a negative symbol" do
              expect(present_with_symbol.to_s(true)).to_not match /-/
            end
          end

          context 'negative' do
            it "should have a negative symbol" do
              expect((-present_with_symbol).to_s(true)).to match /-/
              expect((-present_with_symbol).to_s(true)).to match /^-#{Regexp.quote(present_with_symbol.sym)}\d+\.\d{#{present_with_symbol.decimals}}$/
            end
          end
        end

        context "!present?" do
          context "arg: falsey (default)" do
            it "returns an empty string" do
              [
                [],
                [false],
                [nil]
              ].each do |args|
                expect(blank_with_symbol.to_s(*args)).to eq ''
              end
            end
          end

          context "arg: truthy" do
            it "returns a fully formatted string" do
              expect(blank_with_symbol.to_s(true)).to match /^#{Regexp.quote(blank_with_symbol.sym)}\d+\.\d{#{blank_with_symbol.decimals}}$/
            end
          end
        end
      end

      describe "value" do
        context 'present?' do
          it "should return the converted integer value" do
            expect(StoreAsInt::Base.new('1.0').value).to eq (10 ** subject.accuracy).to_i
            expect(StoreAsInt::Base.new('1.0').value).to be_an Integer
            expect(StoreAsInt::Base.new(1).value).to eq 1
          end
        end

        context '!present?' do
          it "should return 0" do
            expect(StoreAsInt::Base.new.value).to eq 0
            expect(StoreAsInt::Base.new('').value).to eq 0
          end
        end
      end
    end
  end
end
