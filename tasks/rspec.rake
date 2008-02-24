require 'spec/rake/spectask'

#-----------------------------------------------------------------------
# Testing - this is either test or spec, include the appropriate one
#-----------------------------------------------------------------------
namespace :test do

    task :default => :spec

    Spec::Rake::SpecTask.new do |r| 
        r.rcov      = true
        r.rcov_dir  = Stickler::SPEC.local_coverage_dir
        r.libs      = Stickler::SPEC.require_paths
        r.spec_opts = %w(--format specdoc --color)
    end

    if HAVE_HEEL then
        desc "View the code coverage report locally"
        task :coverage => [:spec] do
            sh "heel --root #{Stickler::SPEC.local_coverage_dir}"
        end 
    end
    
end
