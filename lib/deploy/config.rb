module Deploy

  class Config

    class << self

      def config
        @@config ||= {}
        @@config[:default] ||= {}
        @@config[:clazz] ||= {}
        @@config
      end

      def set(key, value)
        self.config[:default][key] = value
      end

      def get(key)
        self.config[:default][key]
      end

      def set_clazz(key, value)
        self.config[:clazz][key] = value
      end

      def get_clazz(key)
        self.config[:clazz][key]
      end

    end

  end

end

