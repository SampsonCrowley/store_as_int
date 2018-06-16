require_relative '../spec_helper'
require_relative '../../lib/store_as_int/exchange_rate'

overridden_constants = [
  ['ACCURACY', 10],
  ['DECIMALS', 4],
  ['SYM', '%'],
]

describe StoreAsInt::ExchangeRate do
  it "inherits from StoreAsInt::Base" do
    expect(subject.is_a?(StoreAsInt::Base)).to eq true
    expect(subject.class.superclass).to eq StoreAsInt::Base
  end

  describe 'Constants' do
    overridden_constants.each do |constant, value|
      it "should default ::#{constant} to '#{value || (value.nil? ? 'nil' : 'false')}'" do
        expect(subject.class.const_get constant).to eq value
      end
    end
  end

  describe 'Singleton Methods' do
    subject { StoreAsInt::ExchangeRate }
    describe 'extend_numerics' do
      it "includes ActsAsExchangeRateInt into Numeric" do
        StoreAsInt::ActsAsExchangeRateInt.instance_methods(false).each do |method|
          expect{ 1.__send__ method }.to raise_error NoMethodError
        end

        subject.extend_numerics

        StoreAsInt::ActsAsExchangeRateInt.instance_methods(false).each do |method|
          expect{ 1.__send__ method }.to_not raise_error
        end
      end
    end
  end
end
