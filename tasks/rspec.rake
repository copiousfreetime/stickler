require 'tasks/config'
if spec_config = Configuration.for_if_exist('test') then

  namespace :test do
  
    task :default => :spec
    
    require 'spec/rake/spectask'
    Spec::Rake::SpecTask.new do |r| 
      r.ruby_opts   = spec_config.ruby_opts
      r.libs        = [ Stickler::Configuration.lib_path, 
                      Stickler::Configuration.root_dir ]
      r.spec_files  = spec_config.files
      r.spec_opts   = spec_config.options

      if rcov_config = Configuration.for_if_exist('rcov') then
        r.rcov      = true
        r.rcov_dir  = rcov_config.output_dir
        r.rcov_opts = rcov_config.rcov_opts
      end

    end
  end

  #if HAVE_HEEL then
  #desc "View the code coverage report locally"
  #task :coverage => [:spec] do
  #sh "heel --root #{Stickler::SPEC.local_coverage_dir}"
  #end 
  #end

end
