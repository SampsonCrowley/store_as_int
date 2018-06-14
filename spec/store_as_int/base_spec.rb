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
  subject { StoreAsInt::Base }
  let(:inherited) { InheritedFromBase }
  let(:fifteen) { StoreAsInt::Base.new(15.00) }
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

    describe 'Constant Accessors' do
      default_constants.each do |constant, value|
        it "should exist for ::#{constant}" do
          expect(subject).to respond_to(constant.downcase.to_sym)
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
            expect(subject.new('1.0').value).to eq 10 ** subject.accuracy
            expect(subject.new('1').value).to eq 10 ** subject.accuracy
            expect(subject.new('+$1.00').value).to eq 10 ** subject.accuracy
            expect(subject.new('+$0.12345').value).to eq 12345
            expect(subject.new('+#0.12345').value).to eq 12345
            expect(subject.new('+#26').value).to eq 2600000
            expect(subject.new('-0.12345').value).to eq -12345
            expect(subject.new('-asaa0.12345').value).to eq 12345
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
      %w(
        is_a?
        is_an?
      ).each do |str|
        describe str do
          it 'is an alias for "kind_of?"' do
            expect([subject, str.to_sym]).to be_an_alias_of(:kind_of?).with(Class)
          end
        end
      end
      describe 'kind_of?' do
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
            expect(subject.is_a? StoreAsInt::Money).to eq false
            expect(subject.is_a? String).to eq false
          end
        end
      end
      describe 'instance_of?' do
        context "own class" do
          it 'returns true' do
          end
        end
      end

      describe 'present?' do
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

      describe "base_float"
      describe "coerce"
      describe "convert"
      describe "decimals" do
        it_behaves_like "a class method instance", :decimals
      end
      describe "inspect"
      describe "method_missing"
      describe "negative_sign"
      describe "sym" do
        it_behaves_like "a class method instance", :sym, '', true
      end
      describe "sym=" do
        it "sets the instance variable @sym" do
          subject.sym = "$"
          expect(subject.sym).to eq '$'
          subject.sym = "#"
          expect(subject.sym).to_not eq '$'
          expect(subject.sym).to eq '#'
        end
      end
      describe "to_d"
      describe "to_f"
      describe "to_h"
      describe "to_i"
      describe "to_json"
      describe "to_s"
      describe "value"
    end
  end
end
