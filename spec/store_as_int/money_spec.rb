require_relative '../spec_helper'
require_relative '../../lib/store_as_int/money'
default_constants = [
  ['ACCURACY', 2],
  ['DECIMALS', 2],
  ['SYM', '$'],
  ['STR_FORMAT', nil],
  ['OPERATORS', nil]
]

describe "StoreAsInt::Money" do
  let(:model) { StoreAsInt::Money }

  context 'Constants' do
    default_constants.each do |constant, value|
      if value
        it "should default ::#{constant} to '#{value || (value.nil? ? 'nil' : 'false')}'" do
          expect(model.const_get constant).to eq value
        end
      else
        it "should not modify ::#{constant} from parent" do
          expect(model.const_get constant).to eq model.superclass.const_get constant
        end
      end
    end
  end
end
