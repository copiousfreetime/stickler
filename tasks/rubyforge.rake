require 'tasks/config'
if rf_conf = Configuration.for_if_exist('rubyforge') then
  #-----------------------------------------------------------------------
  # Rubyforge additions to the task library
  #-----------------------------------------------------------------------
  require 'rubyforge'
  
  prof_conf = Configuration.for('project')

  namespace :dist do
    desc "Release files to rubyforge"
    task :rubyforge => [:clean, :package] do

      rubyforge = ::RubyForge.new

      # make sure this release doesn't already exist
      releases = rubyforge.autoconfig['release_ids']
      if releases.has_key?(prof_conf.name) and releases[prof_conf.name][Stickler::VERSION] then
        abort("Release #{Stickler::VERSION} already exists! Unable to release.")
      end

      config = rubyforge.userconfig
      config["release_notes"]     = prof_conf.description
      config["release_changes"]   = Utils.release_notes_from(proj_conf.history)[Stickler::VERSION]
      config["Prefomatted"]       = true

      puts "Uploading to rubyforge..."
      files = FileList[File.join("pkg","#{prof_conf.name}-#{Stickler::VERSION}*.*")].to_a
      rubyforge.login
      rubyforge.add_release(rf_conf.project, prof_conf.name, Stickler::VERSION, *files)
      puts "done."
    end
  end

  namespace :announce do
    desc "Post news of #{prof_conf.name} to #{rf_conf.project} on rubyforge"
    task :rubyforge do
      subject, title, body, urls = announcement
      rubyforge = RubyForge.new
      rubyforge.login
      rubyforge.post_news(rf_conf.project, subject, "#{title}\n\n#{urls}\n\n#{body}")
      puts "Posted to rubyforge"
    end

  end
end
