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

      def blank?(string)
        string.nil? || string.empty?
      end

      def present?(string)
        !blank?(string)
      end
    end
  end
end

class String
  def blank?
    self.nil? || self.empty?
  end
end

