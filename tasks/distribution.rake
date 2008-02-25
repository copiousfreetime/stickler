#-----------------------------------------------------------------------
# Distribution and Packaging
#-----------------------------------------------------------------------
require 'tasks/config'

# only do this task if the appropriate section from the configuration exists
if pkg_config= Configuration.for_if_exist("packaging") then

  require 'gemspec'
  require 'rake/gempackagetask'

  namespace :dist do
    Rake::GemPackageTask.new(Stickler::GEM_SPEC) do |pkg|
      pkg.need_tar = pkg_config.formats.tgz
      pkg.need_zip = pkg_config.formats.zip
    end

    desc "Install as a gem"
    task :install => [:clobber, :package] do
      sh "sudo gem install -y pkg/#{Stickler::SPEC.full_name}.gem"
    end

    desc "Uninstall gem"
    task :uninstall do 
      sh "sudo gem uninstall -i #{Stickler::SPEC.name} -x"
    end

    desc "dump gemspec"
    task :gemspec do
      puts Stickler::GEM_SPEC
    end

    desc "reinstall gem"
    task :reinstall => [:uninstall, :repackage, :install]

  end
end
