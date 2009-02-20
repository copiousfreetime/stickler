require 'rubygems'
require 'stickler/version'
require 'tasks/config'

Stickler::GEM_SPEC = Gem::Specification.new do |spec|
  proj = Configuration.for('project')
  spec.name         = proj.name
  spec.version      = Stickler::VERSION
  
  spec.author       = proj.author
  spec.email        = proj.email
  spec.homepage     = proj.homepage
  spec.summary      = proj.summary
  spec.description  = proj.description
  spec.platform     = Gem::Platform::RUBY

  spec.post_install_message = <<-msg
  ============================================================
  
  Thank you for installing Stickler!

  * Create a new stickler repository:
      stickler setup /path/to/repo

  * Look at the help:
      stickler help

  ============================================================
  msg


  spec.required_rubygems_version = [ "~> 1.3.0" ]

  spec.add_runtime_dependency( 'highline', "~> 1.4" )
  spec.add_runtime_dependency( 'logging', "~> 0.9" )
  spec.add_runtime_dependency( 'main', "~> 2.8" )

  spec.add_development_dependency( 'rake', "~> 0.8"  )
  spec.add_development_dependency( 'rspec', "~> 1.1" )
  spec.add_development_dependency( 'configuration', "~> 0.0" )
  
  pkg = Configuration.for('packaging')
  spec.files        = pkg.files.all
  spec.executables  = pkg.files.bin.collect { |b| File.basename(b) }
 
  if rdoc = Configuration.for_if_exist?('rdoc') then
    spec.has_rdoc         = true
    spec.extra_rdoc_files = pkg.files.rdoc
    spec.rdoc_options     = rdoc.options + [ "--main" , rdoc.main_page ]
  else
    spec.has_rdoc         = false
  end

  if test = Configuration.for_if_exist?('testing') then
    spec.test_files       = test.files
  end


  if rf = Configuration.for_if_exist?('rubyforge') then
    spec.rubyforge_project  = rf.project
  end
end
