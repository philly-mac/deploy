module Deploy

  class Config

    class << self

      def config
        configatron
      end

      def set(key, value)
        configatron.configure_from_hash({:default => {key => value}})
      end

      def get(key)
        configatron.default.retrieve(key.to_sym, nil)
      end

      def set_clazz(key, value)
        configatron.configure_from_hash({:clazz => {key => value}})
      end

      def get_clazz(key)
        configatron.clazz.retrieve(key.to_sym, nil)
      end

    end

  end

end

