#-----------------------------------------------------------------------
# Documentation
#-----------------------------------------------------------------------

namespace :doc do
    
    # generating documentation locally
    Rake::RDocTask.new do |rdoc|
        rdoc.rdoc_dir   = Stickler::SPEC.local_rdoc_dir
        rdoc.options    = Stickler::SPEC.rdoc_options 
        rdoc.rdoc_files = Stickler::SPEC.rdoc_files
    end

    desc "Deploy the RDoc documentation to #{Stickler::SPEC.remote_rdoc_location}"
    task :deploy => :rerdoc do
        sh "rsync -zav --delete #{Stickler::SPEC.local_rdoc_dir}/ #{Stickler::SPEC.remote_rdoc_location}"
    end

    if HAVE_HEEL then
        desc "View the RDoc documentation locally"
        task :view => :rdoc do
            sh "heel --root  #{Stickler::SPEC.local_rdoc_dir}"
        end
    end
end