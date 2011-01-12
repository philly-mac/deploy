class String
  def camelize
    indexes = [0]
    self.size.times { |i| indexes << (i + 1) if self[i,1] == '_' }
    indexes.each    { |i| self[i] = self[i,1].upcase }
    self.gsub("_", "")
  end
end

