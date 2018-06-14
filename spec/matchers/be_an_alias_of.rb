RSpec::Matchers.define :be_an_alias_of do |aliased|
  match do |args|
    subj, method = args
    method_was_called = false

    expect(subj).to respond_to aliased
    expect(subj.__send__ method, *@args).to eq subj.__send__ aliased, *@args

    $allow_numeric_stubbing = true
    if [*@args].length > 0
      allow(subj).to receive(aliased).with(*@args) { method_was_called = true }
    else
      allow(subj).to receive(aliased) { method_was_called = true }
    end
    subj.__send__ method, *@args
    $allow_numeric_stubbing = false
    method_was_called
  end

  chain :with do |*args|
    @args = args
  end

  failure_message do |args|
    subj, method = args
    "expected #{method} to be an alias of #{aliased}"
  end
end
