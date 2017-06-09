require 'radagen/version'
require 'radagen/generator'

module Radagen
  extend self

  # Predicate to check if obj is an instance of Gen::Generator
  #
  # @param obj [Object] object to be checked
  # @return [Boolean]
  #
  def gen?(obj)
    obj.class == Radagen::Generator
  end

  # Creates a generator that will choose (inclusive)
  # at random a number between lower and upper bounds.
  # The sampling is *with* replacement.
  #
  # @note This is a low level generator and is used to build up most of the generator abstractions
  # @overload choose(Fixnum, Fixnum)
  #   @param lower [Fixnum] set the lower bound (inclusive)
  #   @param upper [Fixnum] set the upper bound (inclusive)
  #   @return [Radagen::Generator]
  #
  # @overload choose(Float, Float)
  #   @param lower [Float] set the lower bound (inclusive)
  #   @param upper [Float] set the upper bound (inclusive)
  #   @return [Radagen::Generator]
  #
  # @example
  #   choose(1, 5).sample(5) #=> [5, 1, 3, 4, 5]
  #
  # @example
  #   choose(0.0, 1.0).sample(5) #=> [0.7892616716655776, 0.9918259286064951, 0.8583139574435731, 0.9567596959947294, 0.3024080166537295]
  #
  def choose(lower, upper)
    raise RangeError.new, 'upper needs to be greater than or equal to lower value' unless upper >= lower
    RG.new { |prng, _| prng.rand(lower..upper) }
  end

  # Creates a generator that 'exposes' the *size*
  # value passed to the generator. *block* is a
  # Proc that takes a fixnum and returns a generator.
  # This can be used to *see*, manipulate or wrap
  # another generator with the passed in size.
  #
  # @param block [Proc] takes a size returning a generator
  # @return [Radagen::Generator]
  #
  # @example Cube the size passed to a generator
  #   sized do |size|
  #     cube_size = size ** 3
  #     choose(1, cube_size)
  #   end
  #
  def sized(&block)
    RG.new do |prng, size|
      sized_gen = block.call(size)
      sized_gen.call(prng, size)
    end
  end

  # Creates a generator that allows you to pin the
  # *size* of a generator to specified value. Think
  # of the *size* as being the upper bound the generator's
  # size can be.
  #
  # @param gen [Radagen::Generator] generator to set the size on
  # @param size [Fixnum] actual size to be set
  # @return [Radagen::Generator]
  #
  # @example Set the size of a integer generator
  #   resize(fixnum, 500).sample(3) #=> [484, -326, -234]
  #
  # @example Without resize
  #   fixnum.sample(3) #=> [0, 1, 1]
  #
  def resize(gen, size)
    RG.new do |prng, _|
      gen.call(prng, size)
    end
  end

  # Creates a generator that allows you to modify the
  # *size* parameter of the passed in generator with
  # the block. The block accepts the size and allows you
  # to change the size at different rates other than linear.
  #
  # @see sized
  # @note This is intended to be used for generators that accept a size. This is partly a convenience function, as you can accomplish much the same with *sized*.
  # @param gen [Radagen::Generator] generator that will be *resized* by the scaled size
  # @param block [Proc] proc that will accept transform and return the size parameter
  # @return [Radagen::Generator]
  #
  # @example Cube size parameter
  #   scaled_nums = scale(string_numeric) do |size|
  #     size ** 3
  #   end
  #
  #   scaled_nums.sample(3) #=> ["", "5", "69918"]
  #
  def scale(gen, &block)
    sized do |size|
      _size = block.call(size)
      resize(gen, _size)
    end
  end

  # Takes a generator and a Proc. The Proc is passed a value
  # taken from calling the generator. You then are free to
  # transform the value before it is returned.
  #
  # @note A value (not a generator) needs to be returned from the Proc.
  # @param gen [Radagen::Generator] generator that produces values passed to Proc
  # @param block [Proc] proc that is intended to manipulate value and return it
  # @return [Radagen::Generator]
  #
  # @example
  #   fmap(fixnum) { |i| [i, i ** i] }.sample(4) #=> [[0, 1], [-1, -1], [2, 4], [-1, -1]]
  #
  def fmap(gen, &block)
    RG.new do |prng, size|
      block.call(gen.call(prng, size))
    end
  end

  # Takes a generator and a Proc. The Proc is passed a value
  # taken from calling the generator. You then can use that
  # value as an input to the generator returned.
  #
  # @note The Proc has to return a generator.
  # @param gen [Radagen::Generator] generator that produces value passed to Proc
  # @param block [Proc] takes a value from generator and returns a new generator using that value
  # @return [Radagen::Generator]
  #
  # @example
  #   bind_gen = bind(fixnum) do |i|
  #     array(string_numeric, {max: i})
  #   end
  #
  #   bind_gen.sample(5) #=> [[], ["1"], ["86"], [], ["64", "25", ""]]
  #
  def bind(gen, &block)
    RG.new do |prng, size|
      inner_gen = block.call(gen.call(prng, size))
      inner_gen.call(prng, size)
    end
  end

  # Takes n generators returning an n-tuple of realized
  # values from generators in arity order.
  #
  # @overload tuple(generator, generator, ...)
  #   @param gens [Radagen::Generator] generators
  #   @return [Radagen::Generator]
  #
  # @example
  #   tuple(string_alphanumeric, uuid, boolean).sample(5) #=> [["", "6e63d2cc-82bf-4b34-b326-e5befeb30309", false], ["A", "2847889f-f93d-4239-86f5-c6411c639554", true], ["", "d04e894f-b35b-4edc-a214-abf76d9c1b60", true], ["05", "7e3ff332-8e35-44ca-905c-8e0538fb14f8", false], ["GR", "3f6c0be8-6b16-4b2b-9510-922961ff0f7a", true]]
  #
  def tuple(*gens)
    raise ArgumentError.new 'all arguments need to be generators' unless gens.all? { |g| gen? g }

    RG.new do |prng, size|
      gens.map do |gen|
        gen.call(prng, size)
      end
    end
  end

  # Creates a generator that when called returns a varying
  # length Array with values realized from the passed in
  # generator. Excepts an options Hash that can contain the
  # keys :min and :max. These will define the minimum and
  # maximum amount of values in the realized Array.
  #
  # @note If you provide a *:min* value then it is good practice to also provide a *:max* value as you can't be sure that the *size* passed to the generator will be greater or equal to :min.
  # @param gen [Radagen::Generator] generator that produces values in the Array
  # @param opts [Hash] the options hash to provide extra context to the generator
  # @option opts [Fixnum] :min (0) minimum number of values in a generated Array
  # @option opts [Fixnum] :max (*size*) maximum number of values in a generated Array
  # @return [Radagen::Generator]
  #
  # @example
  #   array(fixnum).sample(4) #=> [[], [-1], [0, -2], [-2, -1]]
  #
  # @example
  #   array(fixnum, max: 5).sample(4) #=> [[0], [0, 0, -1, 1], [0, 0, -2, 1], [3, 2, -2, -1, 0]]
  #
  # @example
  #   array(fixnum, min: 4, max: 7).sample(4) #=> [[0, 0, 0, 0, 0], [-1, 0, -1, 1, -1], [-2, -2, -1, 2, 0], [0, 2, 3, -1, -2, -2, 3]]
  #
  def array(gen, opts={})
    size_gen = sized do |size|
      min, max = {min: 0, max: size}.merge(opts).values_at(:min, :max)
      raise RangeError.new, "max value (#{max}) needs to be larger than or equal to min value (#{min}), perhaps provide a max value?" unless max >= min
      choose(min, max)
    end

    bind(size_gen) do |_size|
      gens = (0..._size).map { gen }
      tuple(*gens)
    end
  end

  require 'set'

  # Creates a generator that when called returns a varying
  # length Set with values realized from the passed in
  # generator. Excepts the same values and provides similar
  # behavior of Array options.
  #
  # @see array
  # @note If the provided generator generates two of the same values then the set will only contain a single representation of that value.
  # @param gen [Radagen::Generator] generator that produces values in the Set
  # @param opts [Hash] the options hash to provide extra context to the generator
  # @option opts [Fixnum] :min (0) minimum number of values in a generated Set
  # @option opts [Fixnum] :max (*size*) maximum number of values in a generated Set
  # @return [Radagen::Generator]
  #
  # @example
  #   set(fixnum).sample(5) #=> [#<Set: {}>, #<Set: {}>, #<Set: {1, -2}>, #<Set: {-3}>, #<Set: {-1, -4, -3}>]
  #
  def set(gen, opts={})
    fmap(array(gen, opts)) do |array|
      array.to_set
    end
  end

  # Creates a generator that produces Hashes based on the *model_hash*
  # passed in. This model_hash is a Hash of scalar keys and generator
  # values. The hashes returned will have values realized from the
  # generators provided.
  #
  # @param model_hash [Hash<Object, Radagen::Generator>] a hash of keys to generators
  # @return [Radagen::Generator]
  #
  # @example
  #   hash({name: not_empty(string_alpha), age: fixnum_neg, occupation: elements([:engineer, :scientist, :chief])}).sample(4) #=> [{:name=>"r", :age=>-1, :occupation=>:engineer}, {:name=>"n", :age=>-1, :occupation=>:chief}, {:name=>"f", :age=>-2, :occupation=>:engineer}, {:name=>"O", :age=>-2, :occupation=>:chief}]
  #
  def hash(model_hash)
    ks = model_hash.keys
    vs = model_hash.values
    raise ArgumentError.new 'all values in hash need to be a Gen::Generator' unless vs.all? { |g| gen? g }

    fmap(tuple(*vs)) do |vs|
      ks.zip(vs).to_h
    end
  end

  # Creates a generator that when called will return hashes containing
  # keys taken from *key_gen* and values taken from *value_gen*.
  #
  # @note This will create hashes of various sizes and will grow along with the keys and values.
  # @param key_gen [Radagen::Generator] creates the keys used in the hash
  # @param value_gen [Radagen::Generator] creates the values used in the hash
  # @return [Radagen::Generator]
  #
  # @example
  #   hash_map(symbol, fixnum_pos).sample(5) #=> [{}, {:t=>1}, {:DE=>2}, {:nvq=>1, :EN=>2, :L=>2}, {:QTCB=>4, :V=>3, :g=>3, :ue=>2}]
  #
  def hash_map(key_gen, value_gen)
    fmap(array(tuple(key_gen, value_gen))) do |tuple_array|
      tuple_array.to_h
    end
  end

  # Creates a generator taking values from the passed in generator
  # and applies them to the *pred* block, returning only the values
  # that satisfy the predicate. This acts much the same way as
  # enumerable's *#select* method. By default it will try 10 times
  # to satisfy the predicate with different *sizes* passed to the
  # generator. You can provide a count of the number of tries.
  #
  # @param gen [Radagen::Generator] generator that produces values applied to predicate block
  # @param tries [Fixnum] (10) maximum number of tries the generator will make to satify the predicate
  # @param pred [Proc] proc/function that takes a value from gen and returns a truthy or falsy value
  # @return [Radagen::Generator]
  #
  # @example
  #   such_that(string_ascii) { |s| s.length > 4 }.sample(5) #=> ["/%daW", "bQ@t'", "{1%]o", "8j*vzL", "Ga2#Z"]
  #
  def such_that(gen, tries=10, &pred)
    RG.new do |prng, size|
      select_helper(gen, tries, prng, size, &pred)
    end
  end

  # Creates a generator that *empty* values from the provided
  # generator are disregarded. Literally calls #empty? on object.
  # This is a convenience generator for dealing with strings and
  # collection types.
  #
  # @note Of course this will throw if you pass it a generator who's values don't produce types that respond to #empty?
  # @param gen [Radagen::Generator] generator that produces values that #empty? will be called on
  # @return [Radagen::Generator]
  #
  # @example
  #   not_empty(string_ascii).sample(5) #=> ["r", "!R", ";", "}", "HKh"]
  #
  # @example
  #   not_empty(array(string_ascii)).sample(5) #=> [["`"], ["", ""], ["", ""], ["MH(", "gM", "{mz"], ["!", "9;", "c"]]
  #
  def not_empty(gen)
    such_that(gen) { |x| not x.empty? }
  end

  # Creates a generator that when called will select one of the
  # passed in generators returning it's realized value.
  #
  # @overload one_of(generator, generator, ...)
  #   @param gens [Radagen::Generator] generators
  #   @return [Radagen::Generator]
  #
  # @example
  #   one_of(fixnum, char_ascii, boolean).sample(5) #=> [0, "d", false, 1, -1]
  #
  def one_of(*gens)
    bind(choose(0, gens.count - 1)) do |i|
      gens.fetch(i)
    end
  end

  # Creates a generator that when called will select 1..n generators
  # provided and return and Array of realized values from those chosen
  # generators.
  #
  # @note Order of generator selection will be shuffled
  # @overload some_of(generator, generator, ...)
  #   @param gens [Radagen::Generator] generators
  #   @return [Radagen::Generator]
  #
  # @example
  #   some_of(uuid, symbol, float).sample(4) #=> [["be136967-98e9-4b56-a562-1555c2d0dd2e"], [0.3905013788606524, "bf148e98-8454-4482-9b90-b0f3f2813785", :j], [0.40012165933893407, "8e6e4e58-75ed-4295-b53d-c60416c1a975", :bA], [-0.3612584756590138, :m]]
  #
  def some_of(*gens)
    bind(tuple(*gens)) do |_vals|
      bind(choose(1, _vals.count)) do |_count|
        fmap(shuffle(_vals)) do |__vals|
          __vals.take(_count)
        end
      end
    end
  end

  # Returns a generator that when called always returns
  # the value passed in. The identity generator.
  #
  # @param value [Object] object that will always be returned by generator
  # @return [Radagen::Generator]
  #
  # @example
  #   return(["something"]).sample(4) #=> [["something"], ["something"], ["something"], ["something"]]
  #
  def return(value)
    RG.new { |_, _| value }
  end

  # Returns a generator that takes a single element from
  # the passed in collection. Works with object that
  # implement *.to_a*.
  #
  # @note Sampling is *with* replacement.
  # @param coll [Object] collection object that an element will be selected from
  # @return [Radagen::Generator]
  #
  # @example
  #   elements([1,2,3,4,5]).sample(4) #=> [4, 2, 5, 5]
  #
  # @example showing that #.to_a will be called on coll
  #   elements({:this => :this, :that => :that}).sample(2) #=> [[:that, :that], [:that, :that]]
  #
  def elements(coll)
    _coll = coll.to_a

    bind(choose(0, _coll.count - 1)) do |i|
      self.return(_coll.fetch(i))
    end
  end

  # Returns a generator that will create a collection of
  # same length with the elements reordered.
  #
  # @param coll [Object] collection object that elements will be reordered
  # @return [Radagen::Generator]
  #
  # @example
  #   shuffle([:this, :that, :other]).sample(4) #=> [[:other, :that, :this], [:this, :that, :other], [:that, :other, :this], [:other, :this, :that]]
  #
  def shuffle(coll)
    _coll = coll.to_a
    _idx_gen = choose(0, _coll.length - 1)

    fmap(array(tuple(_idx_gen, _idx_gen), {max: _coll.length * 3})) do |swap_indexes|
      swap_indexes.reduce(_coll.clone) do |coll, (i, j)|
        temp = coll[i]
        coll[i] = coll[j]
        coll[j] = temp
        coll
      end
    end
  end

  # Returns a generator that will select a generator from the weighted
  # hash basing the sampling probability on the weights. The weighted_hash
  # is a hash where the keys are generators and values are the sampling
  # weight relative to all other weights, allowing you to control the
  # probability of value sampling.
  #
  # @param weighted_hash [Hash<Radagen::Generator, Fixnum>] a hash of generators to weights
  # @return [Radagen::Generator]
  #
  # @example sample a uuid with three times the probability as string
  #   frequency({uuid => 3, string_ascii => 1}).sample(5) #=> ["", "Y", "3a1d740e-0587-40ca-a9e5-0e550e9afa0d", "2af98855-5bd8-43b4-8b80-1f0ef67712b3", "4fba95b5-9751-492f-889c-a850e7d9b313"]
  #
  def frequency(weighted_hash)
    _weights = weighted_hash.values
    _gens = weighted_hash.keys
    raise ArgumentError.new 'all keys in kvs hash need to be Gen::Generator' unless _gens.all? { |g| gen? g }

    bind(choose(0, _weights.reduce(&:+) - 1)) do |r|
      frequency_helper(_gens, _weights, r, idx=0, sum=0)
    end
  end

  # Returns a generator that will create characters from codepoints 0-255.
  #
  # @note Defaults to UTF-8 encoding
  # @return [Radagen::Generator]
  #
  # @example
  #   char.sample(5) #=> ["\u008F", "c", "0", "#", "x"]
  #
  def char
    fmap(choose(0, 255)) do |v|
      v.chr(CHAR_ENCODING)
    end
  end

  # Returns a generator that will create ascii characters from codepoints 32-126.
  #
  # @note Defaults to UTF-8 encoding
  # @return [Radagen::Generator]
  #
  # @example
  #   char_ascii.sample(5) #=> [".", "P", "=", ":", "l"]
  #
  def char_ascii
    fmap(choose(32, 126)) do |v|
      v.chr(CHAR_ENCODING)
    end
  end

  # Returns a generator that will create alphanumeric characters from
  # codepoint ranges: 48-57, 65-90, 97-122.
  #
  # @note Defaults to UTF-8 encoding
  # @return [Radagen::Generator]
  #
  # @example
  #   char_alphanumeric.sample(5) #=> ["2", "A", "L", "I", "S"]
  #
  def char_alphanumeric
    fmap(one_of(choose(48, 57), choose(65, 90), choose(97, 122))) do |v|
      v.chr(CHAR_ENCODING)
    end
  end

  # Returns a generator that will create alpha characters from
  # codepoint ranges: 65-90, 97-122.
  #
  # @note Defaults to UTF-8 encoding
  # @return [Radagen::Generator]
  #
  # @example
  #   char_alpha.sample(5) #=> ["w", "p", "J", "W", "b"]
  #
  def char_alpha
    fmap(one_of(choose(65, 90), choose(97, 122))) do |v|
      v.chr(CHAR_ENCODING)
    end
  end

  # Returns a generator that will create numeric characters from
  # codepoints 48-57
  #
  # @note Defaults to UTF-8 encoding
  # @return [Radagen::Generator]
  #
  # @example
  #   char_numeric.sample(5) #=> ["8", "5", "7", "0", "8"]
  #
  def char_numeric
    fmap(choose(48, 57)) do |v|
      v.chr(CHAR_ENCODING)
    end
  end

  # Returns a generator that will create strings from
  # characters within codepoints 0-255
  #
  # @note Defaults to UTF-8 encoding
  # @return [Radagen::Generator]
  #
  # @example
  #   string.sample #=> ["", "®", "M", "", "", "Ù¡", "¾H", "<*<", "=\u000FW\u0081", "m¦w"]
  #
  def string
    fmap(array(char)) do |char_array|
      char_array.join
    end
  end

  # Returns a generator that will create strings from
  # ascii characters within codepoints 32-126
  #
  # @note Defaults to UTF-8 encoding
  # @return [Radagen::Generator]
  #
  # @example
  #   string_ascii.sample #=> ["", "^", "", "", "M5a", "", "c", "/gL`Q\\W", "D$I0:F", "`hC|w"]
  #
  def string_ascii
    fmap(array(char_ascii)) do |char_array|
      char_array.join
    end
  end

  # Returns a generator that will create strings from
  # alphanumeric characters within codepoint ranges:
  # 48-57, 65-90, 97-122
  #
  # @note Defaults to UTF-8 encoding
  # @return [Radagen::Generator]
  #
  # @example
  #   string_alphanumeric.sample #=> ["", "e", "yh", "8", "", "8z0", "u441", "L3", "257o", "gWGhZ9"]
  #
  def string_alphanumeric
    fmap(array(char_alphanumeric)) do |char_array|
      char_array.join
    end
  end

  # Returns a generator that will create strings from
  # alpha characters within codepoint ranges: 65-90, 97-122
  #
  # @note Defaults to UTF-8 encoding
  # @return [Radagen::Generator]
  #
  # @example
  #   string_alpha.sample #=> ["", "", "", "H", "i", "Nxc", "gPfIt", "KpGRCl", "BjuiQE", "FCnfPkr"]
  #
  def string_alpha
    fmap(array(char_alpha)) do |char_array|
      char_array.join
    end
  end

  # Returns a generator that will create strings from
  # alpha characters within codepoints 48-57
  #
  # @note Defaults to UTF-8 encoding
  # @return [Radagen::Generator]
  #
  # @example
  #   string_alpha.sample #=> ["", "", "", "H", "i", "Nxc", "gPfIt", "KpGRCl", "BjuiQE", "FCnfPkr"]
  #
  def string_numeric
    fmap(array(char_numeric)) do |char_array|
      char_array.join
    end
  end

  # Returns a generator that will return either true or false.
  #
  # @return [Radagen::Generator]
  #
  # @example
  #   boolean.sample(5) #=> [false, true, false, false, true]
  #
  def boolean
    elements([false, true])
  end

  # Returns a generator that will return fixnums.
  #
  # @return [Radagen::Generator]
  #
  # @example
  #   fixnum.sample(5) #=> [0, 0, -1, 0, -2]
  #
  def fixnum
    sized { |size| choose(-size, size) }
  end

  # Returns a generator that will return positive fixnums.
  #
  # @note 0 is excluded
  # @return [Radagen::Generator]
  #
  # @example
  #   fixnum_pos.sample(5) #=> [1, 1, 3, 2, 4]
  #
  def fixnum_pos
    such_that(natural) { |f| f.positive? }
  end

  # Returns a generator that will return negative fixnums.
  #
  # @note 0 is excluded
  # @return [Radagen::Generator]
  #
  # @example
  #   fixnum_neg.sample(5) #=> [-1, -1, -1, -2, -2]
  #
  def fixnum_neg
    fmap(fixnum_pos) { |f| f * -1 }
  end

  # Returns a generator that will return natural fixnums.
  #
  # @note 0 is included
  # @return [Radagen::Generator]
  #
  # @example
  #   natural.sample(5) #=> [0, 1, 2, 3, 0]
  #
  def natural
    fmap(fixnum) { |f| f.abs }
  end

  # Returns a generator that will return Floats.
  #
  # @return [Radagen::Generator]
  #
  # @example
  #   float.sample(5) #=> [0.0, -0.2676817207773654, 1.0318897544602246, 0.025701283892250792, -3.694547741510407]
  #
  def float
    sized { |size| choose(-size.to_f, size.to_f) }
  end

  # Returns a generator that will return Rationals.
  #
  # @return [Radagen::Generator]
  #
  # @example
  #   rational.sample(5) #=> [(0/1), (-1/1), (1/1), (-1/2), (0/1)]
  #
  def rational
    denom_gen = such_that(fixnum) { |f| not f == 0 }

    fmap(tuple(fixnum, denom_gen)) do |(n, d)|
      Rational(n, d)
    end
  end

  # Returns a generator that will return Byte array representations.
  #
  # @return [Radagen::Generator]
  #
  # @example
  #   bytes.sample(5) #=> [[194, 187], [58], [194, 139], [75], [195, 186, 195, 181, 56]]
  #
  def bytes
    fmap(not_empty(string)) { |s| s.bytes }
  end

  # Returns a generator that will return bytes represented as a
  # string of hex characters. Similar to Random.new.bytes
  #
  # @return [Radagen::Generator]
  #
  # @example
  #   byte_string.sample(5) #=> [ "8&\xB6\xD3\x10", "#\xE3RS\x92 ", "\xC2c\xD2\x19,*", "2", "\xD2s\x80" ]
  #
  def byte_string
    fmap(not_empty(string)) { |s| [s].pack('H*') }
  end

  # Returns a generator that will return Ruby Symbols.
  #
  # @return [Radagen::Generator]
  #
  # @example
  #   symbol.sample(5) #=> [:"7K", :a, :"82", :lhK, :qI4]
  #
  def symbol
    fmap(not_empty(array(char_alphanumeric))) do |char_array|
      char_array.join.intern
    end
  end

  # Returns a random type 4 uuid.
  #
  # @note *size* does not effect derived UUIDs
  # @return [Radagen::Generator]
  #
  # @example
  #   uuid.sample(2) #=> ["1e9a99d0-d412-4362-a36a-6754c055a016", "d28326d7-db57-43ce-85f6-929d73aa3cbf"]
  #
  def uuid
    fmap(array(choose(0, 15), {min: 31, max: 31})) do |nibbles|
      rhex = (8 + (nibbles[15] & 3)).to_s(16)

      [nibbles[0].to_s(16), nibbles[1].to_s(16), nibbles[2].to_s(16), nibbles[3].to_s(16),
       nibbles[4].to_s(16), nibbles[5].to_s(16), nibbles[6].to_s(16), nibbles[7].to_s(16), '-',
       nibbles[8].to_s(16), nibbles[9].to_s(16), nibbles[10].to_s(16), nibbles[11].to_s(16), '-',
       4, nibbles[12].to_s(16), nibbles[13].to_s(16), nibbles[14].to_s(16), '-',
       rhex, nibbles[16].to_s(16), nibbles[17].to_s(16), nibbles[18].to_s(16), '-',
       nibbles[19].to_s(16), nibbles[20].to_s(16), nibbles[21].to_s(16), nibbles[22].to_s(16),
       nibbles[23].to_s(16), nibbles[24].to_s(16), nibbles[25].to_s(16), nibbles[26].to_s(16),
       nibbles[27].to_s(16), nibbles[28].to_s(16), nibbles[29].to_s(16), nibbles[30].to_s(16)].join
    end
  end

  # Returns a random selection of a *simple* type.
  #
  # @note *size* does not effect derived UUID
  # @return [Radagen::Generator]
  #
  # @example
  #   simple_type.sample(5) #=> ["Á", -0.6330060889340847, (-1/1), "Vé", 1]
  #
  def simple_type
    one_of(fixnum, rational, bytes, float, boolean, symbol, char, string, uuid)
  end

  # Returns a random selection of a screen printable *simple* type.
  #
  # @note *size* does not effect derived UUID
  # @return [Radagen::Generator]
  #
  # @example
  #   simple_printable.sample(5) #=> [0, "w", "tr", "aO", -3.072343865486716]
  #
  def simple_printable
    one_of(fixnum, rational, float, boolean, symbol, char_ascii, string_ascii, char_alphanumeric, string_alphanumeric, uuid)
  end

  private

  RG = Radagen::Generator

  CHAR_ENCODING = Encoding::UTF_8

  def frequency_helper(gens, weights, r, idx, sum)
    if r < weights[idx] + sum
      gens[idx]
    else
      frequency_helper(gens, weights, r, idx + 1, weights[idx] + sum)
    end
  end

  def select_helper(gen, tries, prng, size, &pred)
    raise RangeError.new "Exceeded number of tries to satisfy predicate." unless tries >= 1
    unless tries <= 0
      _val = gen.call(prng, size)
      if pred.call(_val)
        _val
      else
        select_helper(gen, tries - 1, prng, size + 1, &pred)
      end
    end
  end

end
