require 'rubygems'
require 'stickler/specification'
require 'stickler/version'
require 'rake'

# The Gem Specification plus some extras for stickler.
module Stickler
    SPEC = Stickler::Specification.new do |spec|
                spec.name               = "stickler"
                spec.version            = Stickler::VERSION
                spec.rubyforge_project  = "stickler"
                spec.author             = "Jeremy Hinegardner"
                spec.email              = "jeremy@hinegardner.org"
                spec.homepage           = "http://stickler.rubyforge.org/"

                spec.summary            = "A Summary of stickler."
                spec.description        = <<-DESC
                A longer more detailed description of stickler.
                DESC

                spec.extra_rdoc_files   = FileList["[A-Z]*"]
                spec.has_rdoc           = true
                spec.rdoc_main          = "README"
                spec.rdoc_options       = [ "--line-numbers" , "--inline-source" ]

                spec.test_files         = FileList["spec/**/*.rb", "test/**/*.rb"]
                spec.files              = spec.test_files + spec.extra_rdoc_files + 
                                          FileList["lib/**/*.rb", "resources/**/*"]
                
                spec.executable         = spec.name
                

                # add dependencies
                # spec.add_dependency("somegem", ">= 0.4.2")
                
                spec.platform           = Gem::Platform::RUBY

                spec.local_rdoc_dir     = "doc/rdoc"
                spec.remote_rdoc_dir    = "#{spec.name}/rdoc"
                spec.local_coverage_dir = "doc/coverage"
                spec.remote_coverage_dir= "#{spec.name}/coverage"

                spec.remote_site_dir    = "#{spec.name}/"

           end
end


