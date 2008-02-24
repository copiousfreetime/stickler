#-----------------------------------------------------------------------
# Website maintenance
#-----------------------------------------------------------------------

namespace :site do
    
    desc "Remove all the files from the local deployment of the site"
    task :clobber do
        rm_rf Stickler::SPEC.local_site_dir
    end

    desc "Update the website on #{Stickler::SPEC.remote_site_location}"
    task :deploy => :build do
        sh "rsync -zav --delete #{Stickler::SPEC.local_site_dir}/ #{Stickler::SPEC.remote_site_location}"
    end

    if HAVE_WEBBY then
        desc "Create the initial webiste template"
        task :init do
            Dir.chdir Stickler::ROOT_DIR do
                ::Webby::Main.run(["website"])
            end
            puts "You will need to edit the website/tasks/setup.rb file at this time."
        end
        
        desc "Build the public website"
        task :build do
            sh "pushd website && rake"
        end
    end

    if HAVE_HEEL then
        desc "View the website locally"
        task :view => :build do
            sh "heel --root #{Stickler::SPEC.local_site_dir}"
        end
    end

end