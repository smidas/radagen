require 'spec_helper'
require_relative '../lib/radagen'

describe 'Radagen' do
  include Radagen

  it 'has a version number' do
    expect(Radagen::VERSION).not_to be nil
  end

  it 'checks if it is a Radagen::Generator with #gen?' do
    class NotAGen; end

    expect(gen?(some_of(string_alpha, string_alphanumeric))).to be_truthy
    expect(gen?(NotAGen)).to be_falsey
  end

  it 'can be sampled for interactive exploration' do
    hash_generator = hash_map(symbol, identity(80))

    samples = hash_generator.sample(20)
    expect(samples.length).to be(20)

    aggregate_failures do
      samples.each do |value|
        expect(value).to be
      end
    end
  end

  it '#to_enum can take a size_min and size_max', :aggregate_failures do
    string_ascii.to_enum(size_min: 300, size_max: 500).take(500).each do |str|
      expect(str.length).to be <= 500
    end
  end

  it '#to_enum can be passed a seed value' do
    gen1 = string_numeric.to_enum(seed: @seed).take(400)
    gen2 = string_numeric.to_enum(seed: @seed).take(400)

    expect(gen1.to_a).to eq(gen2.to_a)
  end

  it 'can #choose a random fixnum' do
    min, max = 4, 30
    choice = choose(min, max).gen( 40, @seed)

    expect(choice).to be_between(min, max)
  end

  it 'can #choose a random float' do
    min, max = 3.0, 60.0
    choice = choose(min, max).gen( 40, @seed)

    expect(choice).to be_between(min, max)
  end

  it 'can expose the size passed to generator with #sized' do
    gen = sized do |size|
      cube_size = size ** 3
      tuple(choose(0, cube_size), identity(cube_size))
    end

    aggregate_failures do
      gen.sample(40).each do |choice, max_size|
        expect(choice).to be_between(0, max_size)
      end
    end
  end

  it 'can set a size value to a generator using #resize' do
    str_values = (0..60).to_a.map do |size|
      resize(string_alphanumeric, 200).gen(size, @seed)
    end

    hash_values = (0..60).to_a.map do |size|
      resize(hash_map(symbol, string_ascii), 200).gen(size, @seed)
    end

    expect(str_values).to all match(str_values.first)
    expect(hash_values).to all match(hash_values.first)
  end

  it 'can expose the size value to a function with #scale' do
    # a convenience generator for interacting with a size value that will be passed to the provided generator
    scaled_strs = scale(string_numeric) do |size|
      size * 5
    end

    scaled_str = scaled_strs.gen(10, 223936931316408050451040303833958099796)
    str = string_numeric.gen(10, 223936931316408050451040303833958099796)

    expect(scaled_str).to eq('822724257908990748731837278449245821216')
    expect(str).to eq('8227242')
  end

  it 'can map over and transform generator values with #fmap' do
    gen = fmap(identity(5)) { |v| v * 5 }
    expect(gen.sample).to all match(25)
  end

  it 'can pass the results of one generator to another with #bind' do
    fixnums = not_empty(array(fixnum))

    elem_of_array = bind(fixnums) do |array|
      tuple(elements(array), identity(array))
    end

    aggregate_failures do
      elem_of_array.to_enum.take(100).each do |elem, array|
        expect(array).to include(elem)
      end
    end

  end

  it 'can produce fixed length arrays with values derived from generators positionally with #tuple' do
    tuples = tuple(string_alphanumeric, fixnum_pos, hash({:key => string_ascii}))

    aggregate_failures do
      tuples.to_enum.take(100).each do |str, num, hash|
        expect(str).to be_instance_of(String)
        expect(num).to be_instance_of(Fixnum)
        expect(hash).to be_instance_of(Hash)
      end
    end
  end

  it 'can produce arrays containing values from passed in generator with #array' do
    arrays = not_empty array(string_ascii)

    aggregate_failures do
      arrays.to_enum.take(100).each do |array|
        expect(array).to include a_kind_of(String)
      end
    end
  end

  it 'can produce arrays with min size with #array' do
    min = 4
    arrays = array(fixnum, min: min, max: 300)

    aggregate_failures do
      arrays.to_enum.take(200).each do |array|
        expect(array.length).to be >= min
      end
    end
  end


  it 'can produce arrays with max size with #array' do
    max = 30
    arrays = array(fixnum,max: max)

    aggregate_failures do
      arrays.to_enum.take(200).each do |array|
        expect(array.length).to be <= max
      end
    end
  end

  it 'can produce sets with min size with #set', :wip do
    min = 4
    arrays = set(fixnum, min: min, max: 300)

    aggregate_failures do
      arrays.to_enum.take(200).each do |set|
        expect(set.length).to be >= min
      end
    end
  end

  it 'can produce set with max size with #set' do
    max = 30
    arrays = set(fixnum, max: max)

    aggregate_failures do
      arrays.to_enum.take(200).each do |set|
        expect(set.length).to be <= max
      end
    end
  end

  it 'can produce hashes based on the model hash with #hash' do
    hashes = not_empty hash({:array => array(fixnum), :string => string_ascii})

    aggregate_failures do
      hashes.to_enum.take(100).each do |hash|
        expect(hash.keys).to include(:array, :string)
        expect(hash[:array]).to be_instance_of(Array)
        expect(hash[:string]).to be_instance_of(String)
      end
    end
  end

  it 'can produce hashes based on key generator and value generator with #hash_map' do
    hashes = hash_map(symbol, string_ascii)

    aggregate_failures do
      hashes.to_enum.take(100).each do |hash|
        expect(hash.keys).to all be_instance_of(Symbol)
        expect(hash.values).to all be_instance_of(String)
      end
    end
  end

  it 'can filter values from a gene rator based on provided predicate with #such_that' do
    positive_fixnums = such_that(fixnum_pos, 20) { |f| f > 4 }

    aggregate_failures do
      positive_fixnums.to_enum.take(100).each do |n|
        expect(n).to be > 4
      end
    end
  end

  it 'can produce non empty collections or strings with #not_empty' do
    non_empty_values = tuple(not_empty(string), not_empty(array(fixnum)), not_empty(set(char_alpha)))

    aggregate_failures do
      non_empty_values.to_enum.take(100).each do |tuple|
        tuple.each do |v|
          expect([v, v.empty?]).to eq([v, false])
        end
      end
    end
  end

  it 'can produce values from one of the provided generators with #one_of' do
    one_of_gen = one_of(fixnum, rational, boolean)

    aggregate_failures do
      one_of_gen.to_enum.take(100).each do |v|
        expect(v).to be_instance_of(Fixnum).or be_instance_of(Rational).or be_instance_of(TrueClass).or be_instance_of(FalseClass)
      end
    end
  end

  it 'can repeatedly produce the same value with #return' do
    val = [:this, :and, :that]
    gen = identity(val)

    aggregate_failures do
      gen.to_enum.take(100).each do |v|
        expect(v).to eq(val)
      end
    end
  end

  it 'can produce values by selecting from a collection with #elements' do
    coll = [:yep, :nope, :maybe]
    elems = elements(coll)

    aggregate_failures do
      elems.to_enum.take(100).each do |v|
        expect(coll).to include(v)
      end
    end
  end

  # scalars
  it 'can produce a range of different characters' do
    characters = [['char', char, (0..255).to_a],
                  ['char_ascii', char_ascii, (32..126).to_a],
                  ['char_alphanumeric', char_alphanumeric, [(48..57).to_a, (65..90).to_a, (97..122).to_a].flatten],
                  ['char_alpha', char_alpha, [(65..90).to_a, (97..122).to_a].flatten],
                  ['char_numeric', char_numeric, (48..57).to_a]]

    characters.each do |name, gen, range|
      aggregate_failures("while checking #{name}") do
        gen.to_enum.take(200).each do |c|
          expect(range.to_a).to include(c.ord)
        end
      end
    end

  end

  it 'can produce type 4 UUID strings', :aggregate_failures do
    uuid.to_enum.take(400).each do |uuid|
      expect(uuid.length).to match(36)
      expect(uuid[14]).to match('4')
      expect(['9', '8', 'a', 'b']).to include(uuid[19])
    end
  end

  it 'can produce fixnums with #fixnum', :aggregate_failures do
    fixnum.to_enum.take(400).each do |f|
      expect(f).to be_instance_of(Fixnum)
    end
  end

  it 'can produce positive fixnums with #fixnum_pos', :aggregate_failures do
    fixnum_pos.to_enum.take(400) do |f|
      expect(f).to be_instance_of(Fixnum).and be_positive?
    end
  end

  it 'can produce negative fixnums with #fixnum_neg', :aggregate_failures do
    fixnum_neg.to_enum.take(400) do |f|
      expect(f).to be_instance_of(Fixnum).and be_negative?
    end
  end

  it 'can produce floats with #float', :aggregate_failures do
    float.to_enum.take(400).each do |f|
      expect(f).to be_instance_of(Float)
    end
  end

  it 'can produce rational numbers with #rational', :aggregate_failures do
    rational.to_enum.take(400).each do |r|
      expect(r).to be_instance_of(Rational)
    end
  end

  it 'can produce values at the correct frequency with #frequency' do
    sample_size = 100000
    gen = frequency({ rational => 3, string_alpha => 2, fixnum => 1 })

    sample_freq = gen.to_enum.take(sample_size).each_with_object(Hash.new(0)) do |v, hash|
      hash[v.class] += 1
    end

    aggregate_failures do
      expect((sample_freq[Rational].to_f/sample_size.to_f).round(2)).to match(a_value_within(0.02).of(0.5))
      expect((sample_freq[String].to_f/sample_size.to_f).round(2)).to match(a_value_within(0.02).of(0.33))
      expect((sample_freq[Fixnum].to_f/sample_size.to_f).round(2)).to match(a_value_within(0.02).of(0.17))
    end
  end

  it 'can take a collection of values and return a reordered collection with #shuffle' do
    coll = [:this, :that, :the, :other, 'more', {:value => 'account'}]

    aggregate_failures do
      shuffle(coll).to_enum.take(100).each do |v|
        expect(v).to include(*coll)
        expect(v.length).to eq(v.length)
      end
    end
  end

end
