require "#{File.dirname(File.expand_path(__FILE__))}/spec_helper"

describe "Utils" do
  it "return a capitalized word" do
    ::Deploy::Utils.capitalize("test").should.equal("Test")
  end
end

