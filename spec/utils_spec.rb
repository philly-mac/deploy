require "#{File.dirname(File.expand_path(__FILE__))}/spec_helper"

describe "Utils" do
  it "should return a capitalized word" do
    ::Deploy::Utils.capitalize("test").should.equal("Test")
  end

  it "should return a camelized word" do
    ::Deploy::Utils.camelize("test_test_test_test").should.equal("TestTestTestTest")
  end
end

