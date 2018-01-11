module Radagen

  class Generator

    def initialize(&gen_proc)
      @gen_proc = gen_proc
    end

    # Realize a value from the generator.
    #
    # @param prng [Object] psuedo random number generator
    # @param size [Fixnum] size used in the generation of the value
    # @return [Object]
    #
    def call(prng, size)
      @gen_proc.call(prng, size)
    end

    # Generate n samples from the generator. Sizing is linear
    # and starts at 0. Max size is defined by #to_enum. This is
    # to *see* what type of values your generator will make.
    #
    # @note max size on samples is set by #to_enum
    # @param n [Fixnum] sample generated values from generator
    # @return [Array<Object>]
    # @see #to_enum
    #
    # @example
    #   fixnum.sample(3) #=> [0, 1, 1]
    #
    def sample(n=10)
      self.to_enum.take(n).to_a
    end

    # Generate a single value from the generator.
    #
    # @param size [Fixnum] *size* passed to the generator
    # @param seed [Fixnum] seed used as the initial state of the generator
    # @return [Object]
    #
    # @example
    #   string_alpha.gen => "Qwad"
    #
    # @example
    #   string_alpha.gen(200, 45362642634632684368) => "IaxBvRLxDIvLBhKezMdMmVZBCGzSJZvVjHkcLHsEchCpZWOmLAUQ"
    #
    def gen(size=30, seed=Random.new_seed)
      prng = prng(seed)
      self.call(prng, size)
    end

    # Create a lazy enumerable of generator values. Size cycles from *size_min* to *size_max*
    #
    # @note the *size* value is the upper bound of the sizes that could be generated
    # @param opts [Hash] options hash to control behavior of enumerator
    # @option opts [Fixnum] :size_min (0) minimum *size* passed to generator in size cycles
    # @option opts [Fixnum] :size_max (300) maximum *size* passed to generator in size cycles
    # @option opts [Fixnum] :seed initial state passed to the pseudo random number generator
    # @return [Enumerator::Lazy]
    #
    # @example
    #   string_ascii.to_enum.take(10).to_a #=> ["", "", ")", "{?", "wE&", "h*hq", "9gm>dG", "9Ljn,(Z", "", "1q7:\\q{"]
    #
    def to_enum(opts={})
      default_opts = {size_min: 0, size_max: 300, seed: Random.new_seed}
      size_min, size_max, seed = default_opts.merge(opts).values_at(:size_min, :size_max, :seed)
      prng = prng(seed)

      (size_min...size_max).cycle.lazy.map do |size|
        @gen_proc.call(prng, size)
      end
    end

    private

    def prng(seed)
      Random.new(seed)
    end

  end

end