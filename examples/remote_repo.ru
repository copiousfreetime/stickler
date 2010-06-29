#-----------------------------------------------------------------------
# Example Gemcutter API server.  This server will respond to 'push' and 
# 'yank' requests and respond as a gem server for those gems pushed to it
#-----------------------------------------------------------------------
$:.unshift File.expand_path( File.join( File.dirname(__FILE__), "..", "lib" ) )

require 'stickler/middleware/gemcutter'
require 'stickler/middleware/compression'

gem_dir = File.join( File.expand_path( File.dirname( __FILE__ ) ), "tmp" )

use ::Stickler::Middleware::Compression
use ::Stickler::Middleware::GemCutter, :repo_root => gem_dir
run ::Sinatra::Base

