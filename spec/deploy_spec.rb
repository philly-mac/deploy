require "#{File.dirname(File.expand_path(__FILE__))}/spec_helper"

describe "Deploy" do
  it "should fail if minimum amount of data us not passed in" do
    opts = [
     {:recipe => '',      :environment => ''},
     {:recipe => '',      :method => ''},
     {:environment => '', :method => ''},
   ]

    summary = "This is a test summary"

    opts.each do |opt|
      ::Deploy::Deploy.init(opt,summary).should.equal(1)
    end
  end
end

