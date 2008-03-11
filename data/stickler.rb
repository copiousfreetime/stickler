#
# Configuration for stickler.  This is pure ruby code that is used to hold the
# meta information about this repository.
#
Stickler::Repository.configuration do |cfg|

  # the upstream gem repository to pull gems from.  This may also be an array of
  # upstream sources.
  cfg.upstream        = "http://gems.rubyforge.org"

  # the directory to store the gem server index.  This is where gems will be
  # served from by a webserver.  If this is a relative directory, it is relative
  # to the directory of the stickler.rb file.
  cfg.gem_server_home  = "dist"

end
