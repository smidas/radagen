# Radagen

[![Build Status](https://travis-ci.org/smidas/radagen.svg?branch=master)](https://travis-ci.org/smidas/radagen)

Radagen is a psuedo random data generator library for the Ruby language built with two primary design goals: *composition* and *sizing*. These two properties allow this library to be used in a range of different applications from simple test data generation, model checking, fuzz testing, database seeding to the foundation of a generative/property based testing framework.

## Requirements
- Ruby 2.0+

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'radagen'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install radagen

## Documentation

[Lastest Release API](http://www.rubydoc.info/gems/radagen)

## Usage

The main use case for Radagen is to create data generators that produce arbitrarily complex values. These generators can then be used in many different contexts. Lets start with a few of the `scalar` generators provided by Radagen.

```ruby
require 'radagen'
gen = Radagen

my_fixnum = gen.fixnum
my_string = gen.string_alphanumeric
```

So far we required the Radagen gem and "namespaced" the Radagen module to `gen`. Throughout the rest of this documentation it will be assume `Radagen` is namespaced to `gen`. Let's take look at what values these generators can produce.

```ruby
my_fixnum.sample => [0, 0, -1, 1, -3, -4, -5, -1, -2, -7]
my_string.sample => ["", "", "jV", "", "7zS", "2", "U9O84Q", "4S", "6Ccw66", "0Sip741V"]
```

`sample` above is a utility method on the `Radagen::Generator` object that allows you to interact with your generator seeing what type of values it will produce. As shown above `sample` returns a sampling of 10 values by default. You can change this number sampled by providing a count.

```ruby
my_string.sample(30) =>  ["",
                          "",
                          "Qo",
                          "T",
                          "X",
                          "qy10O",
                          "Vh",
                          "0omZ",
                          "l30fB",
                          "r08yruW",
                          "27q7zGR",
                          "6jSEk1r",
                          "k667",
                          "v9VUZYnn",
                          "M2K8Hd",
                          "",
                          "4Lu82vRMviY",
                          "LB",
                          "lB",
                          "H0aBry87ykl",
                          "",
                          "8JMjNC",
                          "Gr6lxA",
                          "",
                          "1VfvdCjA9t2PL72Xa",
                          "vI",
                          "lUabvF4Rg06RWl71V27fi53",
                          "qw2Uo71ADT",
                          "550EbA0UX9f9Sc4I",
                          "9QbchgbZtY7C57Eq"]
```

There is something to be noticed about the values produced by `my_string` generator. The values grow in *size* and *complexity* because as `sample` calls the generator it passes a larger and larger *size* value. This is a very important aspect of all Radagen generators and will be detailed further in `sizing`.

### Composition

`scalar` generators are interesting but can only take you so far. We now will explore the ideas around composition. Lets build on the previous generators.

```ruby
my_hash = gen.hash(:fixnum => my_fixnum, :string => my_strings)
my_hash.sample => [{:fixnum=>0, :string=>""},
                   {:fixnum=>1, :string=>"9"},
                   {:fixnum=>-1, :string=>"1"},
                   {:fixnum=>2, :string=>"2F2"},
                   {:fixnum=>1, :string=>""},
                   {:fixnum=>3, :string=>""},
                   {:fixnum=>5, :string=>""},
                   {:fixnum=>1, :string=>"4V9yx"},
                   {:fixnum=>8, :string=>""},
                   {:fixnum=>-1, :string=>"Dy443"}]
```

Above we have built a `hash` generator which uses values taken from previous generators. There is of course little difference between the above and the following:

```ruby
my_hash = gen.hash(:fixnum => gen.fixnum, :string => gen.string_alphanumeric)
my_hash.sample => [{:fixnum=>0, :string=>""},
                   {:fixnum=>0, :string=>""},
                   {:fixnum=>0, :string=>""},
                   {:fixnum=>2, :string=>"W9"},
                   {:fixnum=>-1, :string=>"79BG"},
                   {:fixnum=>2, :string=>"YEF0"},
                   {:fixnum=>0, :string=>"IQDe"},
                   {:fixnum=>-2, :string=>"mRo"},
                   {:fixnum=>-7, :string=>"F958K0"},
                   {:fixnum=>7, :string=>"18T"}]
```

However the following becomes more interesting.

```ruby
meta = gen.hash(:fixnum => gen.fixnum, :string => gen.string_alphanumeric)
individual_account = gen.hash(:account_id => gen.uuid, :type => gen.return('individual'), :meta => meta)
individual_account.sample => [{:account_id=>"d4f6a194-d2d8-4c4f-9a89-df3f477f3dfc", :type=>"individual", :meta=>{:fixnum=>0, :string=>""}},
                              {:account_id=>"e6da491f-0af3-4ab4-9529-00a5025cbbde", :type=>"individual", :meta=>{:fixnum=>-1, :string=>""}},
                              {:account_id=>"4c3a3ebb-0aa3-4fc7-9c66-022ef2c1b77a", :type=>"individual", :meta=>{:fixnum=>-1, :string=>""}},
                              {:account_id=>"2a21493e-5ea7-4ae4-b813-bfe7052c5ba0", :type=>"individual", :meta=>{:fixnum=>-2, :string=>""}},
                              {:account_id=>"54a06f43-35bf-4b86-af36-499164fdec0e", :type=>"individual", :meta=>{:fixnum=>2, :string=>"lYnP"}},
                              {:account_id=>"17d42c28-c9a2-484d-a54f-3063fba893a2",
                               :type=>"individual",
                               :meta=>{:fixnum=>-4, :string=>"92e8k"}},
                              {:account_id=>"c77a7dc6-7c13-4d68-b5ff-dd4d4d22366f", :type=>"individual", :meta=>{:fixnum=>4, :string=>"gEDq"}},
                              {:account_id=>"f0e2b910-70c7-4b65-9dd1-9e89ef03ec00",
                               :type=>"individual",
                               :meta=>{:fixnum=>3, :string=>"e2EYLzk"}},
                              {:account_id=>"7bce02de-6d77-4e4e-91c9-8f518cc73223",
                               :type=>"individual",
                               :meta=>{:fixnum=>4, :string=>"Qnh5Z"}},
                              {:account_id=>"8781bf21-85f0-40f4-b407-85805da60ba6", :type=>"individual", :meta=>{:fixnum=>-1, :string=>"Z"}}]
```

The `hash` generator combinator conveniently will nest any generator. But what if you would like to make your own combinators? There are two primitives to work with; `bind` and `fmap`.

```ruby
domain = gen.elements(['gmail.com', 'mailinator.com'])
name = gen.string_ascii

email_account = gen.fmap(gen.tuple(name, domain)) do |name, domain|
    "#{name}@#{domain}"
end

email_account.sample => ["@gmail.com", "r@gmail.com", "U@gmail.com", "mj@gmail.com", "z^@mailinator.com", "B_@mailinator.com", "(t-f;@gmail.com", "@gmail.com", ")3-@mailinator.com", "n@mailinator.com"]
```

Lets walk thru the above example. `elements` will randomly select an element from the array you pass it (ex. 'gmail.com' or 'mailinator.com'). `string_ascii` will produce strings containing the *ascii* band of characters. `fmap` will take values from a generator, which in this case was a two `tuple` with the first value taken from the *name* generator and the second taken from the *domain* generator, and passes those values to a `block`. Within the block we do some destructuring to the tuple and with string interpolation we return an email account string. Note the block passed to `fmap` requires you return a *value* NOT another generator.

The first example you noticed has an *empty* name which isn't a valid email address. We see our first example of how a 'stocastic' like tool can challenge our assumptions, or at least forces you to consider the domain you are working a little deeper.

If you don't want the generator to produce *empty* names you could do the following:

```ruby
name = gen.not_empty(gen.string_ascii)
name.sample => ["1", "G", "y", "K", "<xv", "|5`", "u4GgC", "^", "n(]yZ2", "V7-"]
```

Using `not_empty` here takes the `string_ascii` generator, returning another generator that won't produce empty strings.

`bind` is similar to `fmap` but the block instead of returning a *value* needs to return a `Radagen::Generator`.

```ruby
account = gen.hash({:id => gen.uuid, :name => gen.string_alpha, :comment_count => gen.fixnum_pos})
accounts = gen.not_empty(gen.array(account)) #an array of non-empty accounts

accounts_and_selection = gen.bind(accounts) do |accounts|
    gen.tuple(gen.identity(accounts), gen.elements(accounts))
end

accounts_and_selection.sample => [[[{:id=>"8f9308be-976f-447b-b207-3e4f3391d8da", :name=>"f", :comment_count=>1}], {:id=>"8f9308be-976f-447b-b207-3e4f3391d8da", :name=>"f", :comment_count=>1}],
                                  [[{:id=>"f28cde53-4f8f-4548-9192-57c3b44af73c", :name=>"Ry", :comment_count=>2}, {:id=>"5b45b99a-1a8a-4674-9ad5-f5c706d27315", :name=>"Hl", :comment_count=>2}], {:id=>"5b45b99a-1a8a-4674-9ad5-f5c706d27315", :name=>"Hl", :comment_count=>2}],
                                  [[{:id=>"3e97741d-107d-4cab-ae11-323b1ef42668", :name=>"Y", :comment_count=>2}], {:id=>"3e97741d-107d-4cab-ae11-323b1ef42668", :name=>"Y", :comment_count=>2}],
                                  [[{:id=>"63e812b2-e1b2-4528-acd2-f36d0f323dbd", :name=>"", :comment_count=>1}], {:id=>"63e812b2-e1b2-4528-acd2-f36d0f323dbd", :name=>"", :comment_count=>1}]]
```

`accounts_and_selection` will create an array of accounts and then randomly select one of those accounts returning a two-tuple of that representation. This type of pattern is very helpful when you want to setup state in a system and then interact with one or more of the objects. Why create a generator that does the selection for you and not just select an element after the values from the generator that have been produced? Reproducibility. Being able to rerun the same generator with the same *seed*, producing the same array of accounts and selection is important when using this library in a testing context or in any context really.

### Seeding

*Seeding* the generator is simply providing a starting state to the [pseudo random number generator](https://en.wikipedia.org/wiki/Pseudorandom_number_generator) so that you can repeatably produce the same values from your generator.

#### gen
```ruby
seed = 5647326586234654723645

accounts_and_selection.gen(5, seed) => [[{:id=>"0cc609b8-7ada-4192-be41-1f2b29369b14", :name=>"Kiq", :comment_count=>5}, {:id=>"cc8e373b-1a06-4d2c-adad-bb18f9d9b10f", :name=>"vU", :comment_count=>3}], {:id=>"0cc609b8-7ada-4192-be41-1f2b29369b14", :name=>"Kiq", :comment_count=>5}]

accounts_and_selection.gen(5, seed) => [[{:id=>"0cc609b8-7ada-4192-be41-1f2b29369b14", :name=>"Kiq", :comment_count=>5}, {:id=>"cc8e373b-1a06-4d2c-adad-bb18f9d9b10f", :name=>"vU", :comment_count=>3}], {:id=>"0cc609b8-7ada-4192-be41-1f2b29369b14", :name=>"Kiq", :comment_count=>5}]
```

Taking our `account_and_selection` generator we created above, providing a *seed* value and a size we were able to reproduce the same generated value. In this example using the `gen` method, we can pass in the *size* and *seed* to the generator. Note the *size* value should also be seen as a state value as it will influence the value produced. The `sample` method does NOT provide this level of interactively and is intended for exploratory interaction in a console.

#### to_enum
```ruby
accounts_and_selection.to_enum(seed: 5647326586234654723645).take(6).to_a => [[[{:id=>"609b87ad-a192-4be4-91f2-b29369b14eee", :name=>"Kiq", :comment_count=>4},
                                                                                {:id=>"cc8e373b-1a06-4d2c-adad-bb18f9d9b10f", :name=>"vU", :comment_count=>4},
                                                                                {:id=>"004839da-0ea1-4545-bf74-211b1515e3c1", :name=>"OI", :comment_count=>2},
                                                                                {:id=>"d59b453c-da7e-45d6-8d44-5a39123c1ce6", :name=>"", :comment_count=>1}],
                                                                               {:id=>"d59b453c-da7e-45d6-8d44-5a39123c1ce6", :name=>"", :comment_count=>1}],
                                                                              [[{:id=>"1f11bc82-c45a-4ab6-8528-eaf0a0b565f3", :name=>"sC", :comment_count=>4}, {:id=>"b2fa4c7b-0bb6-4ff0-9f69-ac709f703b02", :name=>"x", :comment_count=>3}], {:id=>"1f11bc82-c45a-4ab6-8528-eaf0a0b565f3", :name=>"sC", :comment_count=>4}],
                                                                              [[{:id=>"f68e86b3-6b64-4e0d-a184-be9a04dd1101", :name=>"q", :comment_count=>1}, {:id=>"371fe60e-7cd8-40e0-bf8d-d06762978271", :name=>"", :comment_count=>1}], {:id=>"371fe60e-7cd8-40e0-bf8d-d06762978271", :name=>"", :comment_count=>1}],
                                                                              [[{:id=>"30fa9545-b504-443d-8bb5-0a0a87acd2a3", :name=>"TZ", :comment_count=>4}, {:id=>"f8778a9b-2030-45ee-a82f-a7eddbad06c9", :name=>"b", :comment_count=>2}], {:id=>"f8778a9b-2030-45ee-a82f-a7eddbad06c9", :name=>"b", :comment_count=>2}],
                                                                              [[{:id=>"d29f472d-55ea-4464-8b93-91d741b69db5", :name=>"oQc", :comment_count=>2}, {:id=>"448ae1c8-c6c6-40d5-a8ed-cd96dcf05c83", :name=>"", :comment_count=>1}], {:id=>"448ae1c8-c6c6-40d5-a8ed-cd96dcf05c83", :name=>"", :comment_count=>1}]]
```

You can also leverage the `to_enum` method which will return an enumerable representing a lazy infinite sequence of values taken from the generator. Seen above with a provided *seed*, `to_enum` also has the ability to control the sequence of sizes passed to the generator when called. See the API docs for more details.

### Sizing

Sizing provides the ability for a generator to produce values of varying degrees of well, *size*. Size has different meaning depending on the context of the generator being used. In some cases generators don't honor the size parameter at all. Examples being `uuid` and `identity`. When a generator is called to produce a value the *size* that is passed in represents the *upper bound* of all possible sizes starting from zero that could be generated. Why? This is so that methods like `to_enum`, `sample` and `gen` don't return a predictable linear growth of values as they are passed ever increasing size values. It is also why this library and libraries like it seem to have the ability to walk thru progressively more complex values "randomly", perhaps challenging boundary assumptions of a model.

```ruby
5.times { p gen.fixnum.gen(size: 2) } => 2 0 -1 1 -2

5.times { p gen.string.gen(size: 300) } => "oysO930W8B4QU02J05qEWPn6R6H7xTZKFGbG6Hpo28b"
                                           "R021N1tw0927BXZP7GbzgRE4rA5t46785g27jsztMRlaz571XzHoi6yBv22ec97194yByN3KIYM3EX1XiRrA08Y32S5i2AvkevMRLClA8Xsb0N7R"
                                           "3zFiC25U5495KY52FcB1B12txoA6xlFc83TJ97j9ytKSfi0rs1EwSILytRyMy2S5F70TrT6H457teJkVk5fr"
                                           "VaLYheY512yh2qsj2MV31dl7oV56kWmmLlPSDIJwd74mOcyYfQft8N9756VfM5ExtBHql9TnRWl15j3beLww4p176G48s5q8bEWS0Nwcx7RX0WBz2nO412k7fWGi3nmxn8i156C45AHS27ttTB34sT0MiY63HWG0rbXLXnt41d3m5HiWmbnyh9yL36KH3TL4NMwK4vV0A9gZ6DpLrvPUWYaNYgEqQ0MGll1d2009l388upimkl71xaglmK97r7EDA491"
                                           "82Q78FWpl1992nXtPUP2cF0rnM7jUPo0M6F8VgvbrQjHY4Var31H0aY94OF0Np6mlxM648S38LBvTrjZObsGn2eB9RPqzqWOlzMD0j71UKRZU90L7B95B5MdZMviaj5vml3JkkIODi6QZQWUobQt4Gr6b0mqR69UQ77897BuK2VjmFdNPLx4z8we7Bk0vU5o6DcJQgxOu7ZP"

```

There a few methods that can be used to have finer grained control over the size being passed to a generator. See `resize`, `scale`, and for some generators `not_empty` in the API docs.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt with pry that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/smidas/radagen.

## Attribution

Radagen was greatly influenced by the generator API found in [test.check](https://github.com/clojure/test.check) and shares many of the same naming conventions. I have a great deal of gratitude to the contributors and maintainers of that library.

## TODO
- More example documentation
- Make the `set` generator honor *min* elements
- Implement a Bignum generator with a good enough sampling distribution.
- Explore and implement the need for a splittable PRNG.

## License

Radagen is released under the [MIT License](https://github.com/smidas/radagen/blob/master/LICENSE).