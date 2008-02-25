#-----------------------------------------------------------------------
# Website maintenance
#-----------------------------------------------------------------------
if site_conf = Configuration.for_if_exist("website") then
  namespace :site do

    desc "Remove all the files from the local deployment of the site"
    task :clobber do
      rm_rf site_conf.local_dir
    end

    desc "Update the website on #{site_conf.remote_location}"
    task :deploy => :build do
      sh "rsync -zav --delete #{site_conf.local_dir} #{site_conf.remote_location}"
    end

    if try_lib("webby") then
      desc "Create the initial webiste template"
      task :init do
        Dir.chdir Stickler::Configuration.root_dir do
          ::Webby::Main.run(["website"])
        end
        puts "You will need to edit the website/tasks/setup.rb file at this time."
      end

      desc "Build the public website"
      task :build do
        sh "pushd website && rake"
      end
    end


    if try_lib("heel") then
      desc "View the website locally"
      task :view => :build do
        sh "heel --root #{site_conf.local_dir}"
      end
    end
  end
end
