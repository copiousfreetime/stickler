#-----------------------------------------------------------------------
# Example rackup file for serving up a single repository.  This repository
# will respond to index and gem requests.
#-----------------------------------------------------------------------
$:.unshift File.expand_path( File.join( File.dirname(__FILE__), "..", "lib" ) )

require 'stickler/middleware/compression'
require 'stickler/middleware/repo_local'

gem_dir = File.join( File.expand_path( File.dirname( __FILE__ ) ), "data" )

use ::Stickler::Middleware::Compression
use ::Stickler::Middleware::RepoLocal, :repo_root => gem_dir
run ::Sinatra::Base
