#-----------------------------------------------------------------------
# Example rackup file for serving up a single repository.  This repository
# will respond to index and gem requests.
#-----------------------------------------------------------------------
$:.unshift File.expand_path( File.join( File.dirname(__FILE__), "..", "lib" ) )

require 'stickler/middleware/compression'
require 'stickler/middleware/local'

gem_dir = File.expand_path( File.join( File.dirname( __FILE__ ), *%w[ .. spec data ]))

puts gem_dir
use ::Stickler::Middleware::Compression
use ::Stickler::Middleware::Local, :repo_root => gem_dir
run ::Sinatra::Base
