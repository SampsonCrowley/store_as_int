require "set"

shared_examples_for "a class method instance" do |method, default = 0, with_setter = false|
  let(:symbolized_method) { "#{method}".to_sym }
  let(:symbolized_var) { "@#{method}".to_sym }
  let(:returned_val) { -> { subject.__send__ symbolized_method } }

  it "reads from an instance variable" do
    expect(returned_val.call).to eq subject.instance_variable_get(symbolized_var)
  end

  context "default" do
    it "is equal to the class method || default" do
      expect(returned_val.call).to eq (subject.class.__send__(method) || default)
    end

    it "#{with_setter ? 'has' : 'does not have'} a setter method" do
      expect(subject).__send__("to#{with_setter ? '' : '_not'}", respond_to("#{method}="))
    end
  end

  context "modified instance variable" do
    it "returns the modified value" do
      10.times do
        val = rand(10..100)
        subject.instance_variable_set(symbolized_var, val)
        expect(returned_val.call).to eq val
      end
    end
  end
end
