#-----------------------------------------------------------------------
#-*- vim: set ft=ruby: -*-
#
# Example rackup file for serving up a null repository.  This really 
# would never be used in the wild, but it shows the basics of what 
# is required to setup a stickler webstack
#-----------------------------------------------------------------------
$:.unshift File.expand_path( File.join( File.dirname(__FILE__), "..", "lib" ) )

require 'stickler/middleware/compression'
require 'stickler/middleware/index'

gem_dir = File.join( File.expand_path( File.dirname( __FILE__ ) ), "tmp" )

use ::Stickler::Middleware::Compression
use ::Stickler::Middleware::Index, :repo_root => gem_dir
run ::Sinatra::Base
