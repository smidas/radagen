module Radagen

  class Generator

    def initialize(&gen_proc)
      @gen_proc = gen_proc
    end

    # Realize a value from the generator.
    #
    # @param prng [Object] psuedo random number generator
    # @param size [Fixnum] size used in the generation of the value
    #
    def call(prng, size)
      @gen_proc.call(prng, size)
    end

    # Generates n samples from the generator. Sizing is linear
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

    # Creates a lazy enumerable of generator values. Size cycles from 0 to *size_max*
    #
    # @param opts [Hash] options hash to control behavior of enumerator
    # @option opts [Fixnum] :size_max (300) maximum size passed to generator in size cycles
    # @option opts [Fixnum] :seed initial state/seed passed to the pseudo random number generator
    # @return [Enumerator::Lazy]
    #
    # @example
    #   string_ascii.to_enum.take(10).to_a #=> ["", "", ")", "{?", "wE&", "h*hq", "9gm>dG", "9Ljn,(Z", "", "1q7:\\q{"]
    #
    def to_enum(opts={})
      size_max, seed = {size_max: 300, seed: Random.new_seed}.merge(opts).values_at(:size_max, :seed)
      prng = Random.new(seed)

      (0...size_max).cycle.lazy.map do |size|
        @gen_proc.call(prng, size)
      end
    end

  end

end