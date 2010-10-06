# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{foo}
  s.version = "2.0.0a"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jeremy Hinegardner"]
  s.date = %q{2010-06-23}
  s.description = %q{foo gem prerelease}
  s.email = %q{jeremy@hinegardner.org}
  s.files = ["README.rdoc", "lib/foo.rb", "bin/foo", "Rakefile", "foo.gemspec"]
  s.has_rdoc = false
  s.homepage = %q{http://github.com/copiousfreetime/stickler}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{foo gem prerelease}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rake>, [">= 0"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
  end
end

