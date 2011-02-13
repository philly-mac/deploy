# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ffaker}
  s.version = "1.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Emmanuel Oga"]
  s.date = %q{2011-01-18}
  s.description = %q{Faster Faker, generates dummy data.}
  s.email = %q{EmmanuelOga@gmail.com}
  s.extra_rdoc_files = ["README.rdoc", "LICENSE"]
  s.files = ["History.txt", "LICENSE", "README.rdoc", "Rakefile", "ffaker.gemspec", "lib/ffaker.rb", "lib/ffaker/address.rb", "lib/ffaker/company.rb", "lib/ffaker/geolocation.rb", "lib/ffaker/internet.rb", "lib/ffaker/lorem.rb", "lib/ffaker/name.rb", "lib/ffaker/name_cn.rb", "lib/ffaker/phone_number.rb", "lib/ffaker/utils/array_utils.rb", "lib/ffaker/utils/module_utils.rb", "scripts/benchmark.rb", "scripts/profile.sh", "scripts/profiling.rb", "test/helper.rb", "test/test_address.rb", "test/test_array_utils.rb", "test/test_company.rb", "test/test_faker.rb", "test/test_faker_internet.rb", "test/test_faker_name.rb", "test/test_faker_name_cn.rb", "test/test_geolocation.rb", "test/test_lorem.rb", "test/test_module_utils.rb", "test/test_phone_number.rb"]
  s.homepage = %q{http://github.com/emmanueloga/ffaker}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{ffaker}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Faster Faker, generates dummy data.}
  s.test_files = ["test/test_address.rb", "test/test_array_utils.rb", "test/test_company.rb", "test/test_faker.rb", "test/test_faker_internet.rb", "test/test_faker_name.rb", "test/test_faker_name_cn.rb", "test/test_geolocation.rb", "test/test_lorem.rb", "test/test_module_utils.rb", "test/test_phone_number.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
