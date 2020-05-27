# StoreAsInt
## Seamlessly store and compare decimal based values as integers

```
gem install store_as_int
```

### Usage

```
StoreAsInt::TypeToUse.new(value)
```

```
StoreAsInt.type_to_use(value)
```

Values passed to StoreAsInt can be a `String`, `Numeric`, Or `Integer`

If an `Integer` is passed directly to StoreAsInt, it is assumed that is the value that should be stored directly, and no conversion will take place


### Built In Types

#### Money ($1.01)
decimals: 2
accuracy: 2
symbol: $
```
StoreAsInt::Money.new(value)
StoreAsInt.money(value)
```

#### ExchangeRate (%1.0000000001)
decimals: 4
accuracy: 10
symbol: %
```
StoreAsInt::ExchangeRate.new(value)
StoreAsInt.exchange_rate(value)
```


### Register New Type
```
StoreAsInt.register(under_scored_class_name, base_value = 1 (i.e. 100 for dollars), number_of_decimals = 0, symbol_to_use = '', &block_to_use_for_to_s_formatting)

StoreAsInt::CamelCaseClassName.new(value)
StoreAsInt.under_scored_class_name(value)
```

### Testing
```
bundle exec rspec
```
