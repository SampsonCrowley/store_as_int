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

describe 'StoreAsInt::Base' do
  let(:model) { StoreAsInt::Base }
  let(:inherited) { InheritedFromBase }

  context 'Constants' do
    default_constants.each do |constant, value|
      it "should default ::#{constant} to '#{value || (value.nil? ? 'nil' : 'false')}'" do
        expect(model.const_get constant).to eq value
      end
    end
  end

  context 'Singleton Methods' do
    context 'Attribute Accessors' do
      default_constants.each do |constant, value|
        it "should exist for ::#{constant}" do
          expect(model).to respond_to(constant.downcase.to_sym)
          expect(model.__send__ constant.downcase).to eq model.const_get constant
        end

        it "should scope inherited #{constant} accessor to that class" do

          expect(inherited.base).to eq 1000

          default_constants.each do |constant, value|
            expect(inherited.__send__ constant.downcase).to_not eq model.__send__ constant.downcase
            expect(inherited.__send__ constant.downcase).to_not eq model.__send__ constant.downcase
            expect(model.base)
            expect(inherited.decimals).to eq 3
          end
        end
      end
    end

    describe :=== do
      it 'should accept all numeric values' do
        [1, 2.5, BigDecimal.new(1)].each do |val|
          expect(model === val).to be true
        end
      end

      it 'should accept numeric strings' do
        expect(model === '2.34').to be true
        expect(model === '+2.34').to be true
        expect(model === '-2.34').to be true
        expect(model === 'ASFD').to be false
        expect(model === '2.3.4').to be false
      end

      it "should also return true for it's own subclasses" do
        expect(model === inherited).to be true
        expect(inherited === model).to be false
      end
    end
  end

  context 'Instance Methods' do
    describe '#initialize' do
      it 'defaults to 0' do
        expect(StoreAsInt::Base.new.value).to eq 0
      end

      it "properly cooerces numeric types to ::BASE accuracy" do
        expect(model.new(1.0).value).to eq 10 ** 5
        expect(model.new(1.to_f).value).to eq 10 ** 5
        expect(model.new(-1.to_f).value).to eq -(10 ** 5)
        expect(model.new(0.1234).value).to eq 12340
        expect(model.new(0.123456789).value).to eq 12345
        expect(model.new(1234.to_f).value).to eq 1234 * (10 ** 5)
        expect(model.new(BigDecimal.new(0.1234567890, 10)).value).to eq 12345
      end

      it "cooerces numeric strings" do
        expect(model.new('1.0').value).to eq 10 ** 5
        expect(model.new('1').value).to eq 10 ** 5
        expect(model.new('+$1.00').value).to eq 10 ** 5
        expect(model.new('+$0.12345').value).to eq 12345
        expect(model.new('+#0.12345').value).to eq 12345
        expect(model.new('+#26').value).to eq 2600000
        expect(model.new('-0.12345').value).to eq -12345
        expect(model.new('-asaa0.12345').value).to eq -12345
        expect(model.new('ASDF').value).to eq 0
      end

      it "directly stores integers" do
        (1..10000).each do |i|
          expect(model.new(i).value).to eq i
        end

        expect(model.new(10 ** 5).to_s).to eq '1.00'

        (1..10).each do |i|
          front = i < 5 ? '0' : ('1' + (i > 5 ? '0' * (i - 5) : ''))
          back = ((i == 3) && '01') || ((i == 4) && '10') || '00'
          expect(model.new(10 ** i).to_s).to eq "#{front}.#{back}"
        end
      end
    end

    context 'Comparison Methods' do
      describe '<=>' do
        let(:zero) { model.new }
        let(:fifteen) { model.new(15.00) }

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
        let(:zero) { model.new }
        let(:fifteen) { model.new(15.00) }

        it 'initializes the "other" value then compares values' do
          expect(-1 == zero).to be false
          expect(0 == zero).to be true
          expect(0.0 == zero).to be true

          expect((15 * (10 ** 5)) == fifteen).to be true
          expect(fifteen == (15 * (10 ** 5))).to be true
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
        let(:zero) { model.new }
        let(:fifteen) { model.new(15.00) }

        it 'is an alias for ==' do
          expect(-1 === zero).to be false
          expect(0 === zero).to be true
          expect(0.0 === zero).to be true

          expect((15 * (10 ** 5)) === fifteen).to be true
          expect(fifteen === (15 * (10 ** 5))).to be true
          expect(15.0 === fifteen).to be true
          expect(fifteen === 15.0).to be true
          expect(BigDecimal.new(15, 5) === fifteen).to be true
          expect(fifteen === BigDecimal.new(15, 5)).to be true

          expect(fifteen === 14.0).to be false
          expect(14.0 === fifteen).to be false
          expect(fifteen === 16.0).to be false
          expect(16.0 === fifteen).to be false
        end
      end
    end

    context 'Boolean Methods' do
      describe 'is_a?'
      describe 'is_an?'
      describe 'kind_of?'
      describe 'instance_of?'
      describe 'present?'
    end

    context 'Value Methods' do
      describe "accuracy"
      describe "as_json"
      describe "base"
      describe "base_float"
      describe "coerce"
      describe "convert"
      describe "decimals"
      describe "inspect"
      describe "method_missing"
      describe "negative_sign"
      describe "sym"
      describe "sym="
      describe "to_d"
      describe "to_f"
      describe "to_i"
      describe "to_s"
      describe "value"
    end
  end
end
