# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{bacon}
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Christian Neukirchen"]
  s.date = %q{2008-11-30}
  s.default_executable = %q{bacon}
  s.description = %q{Bacon is a small RSpec clone weighing less than 350 LoC but nevertheless providing all essential features.  http://github.com/chneukirchen/bacon}
  s.email = %q{chneukirchen@gmail.com}
  s.executables = ["bacon"]
  s.extra_rdoc_files = ["README", "RDOX"]
  s.files = ["COPYING", "README", "Rakefile", "bin/bacon", "lib/autotest/bacon.rb", "lib/autotest/bacon_rspec.rb", "lib/autotest/discover.rb", "lib/bacon.rb", "test/spec_bacon.rb", "test/spec_should.rb", "RDOX", "ChangeLog"]
  s.homepage = %q{http://chneukirchen.org/repos/bacon}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{a small RSpec clone}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
