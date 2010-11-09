module Deploy
  class Utils
    class << self
      def capitalize(word)
        "#{word[0,1].upcase}#{word[1,word.size - 1]}"
      end
    end
  end
end

