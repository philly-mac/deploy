module Deploy
  class Util
    class << self

      def camelize(string)
        indexes = [0]
        string.size.times { |i| indexes << (i + 1) if string[i,1] == '_' }
        indexes.each    { |i| string[i] = string[i,1].upcase }
        string.gsub("_", "")
      end

    end
  end
end