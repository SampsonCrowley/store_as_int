require_relative 'spec_helper'
require_relative '../lib/store_as_int'

describe "StoreAsInt" do
  it "should include a shortcut to StoreAsInt::Money by default" do
    expect(StoreAsInt).to respond_to(:money)
  end
  it "should include a shortcut to StoreAsInt::ExchangeRate by default" do
    expect(StoreAsInt).to respond_to(:exchange_rate)
  end
  it "should provide a helper to register new storage classes" do
    expect(StoreAsInt).to respond_to(:register)
  end
end
