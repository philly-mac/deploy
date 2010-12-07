module Deploy
  class Utils
    class << self
      def capitalize(word)
        "#{word[0,1].upcase}#{word[1,word.size - 1]}"
      end

      def camelize(word)
        indexes = [0]
        word.size.times { |i| indexes << (i + 1) if word[i,1] == '_' }
        indexes.each    { |i| word[i] = word[i,1].upcase }
        word.gsub("_", "")
      end
    end
  end
end

