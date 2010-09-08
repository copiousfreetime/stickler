#-----------------------------------------------------------------------
# -*- vim: set ft=ruby: -*-
#
# An Example remote repository that implements all the methods that are
# required to satisfy being talked to by a Respository::Remote client.
# This means it needs to speak:
# - the gem cutter api
# - the modern gem server ai
# 
#-----------------------------------------------------------------------
$:.unshift File.expand_path( File.join( File.dirname(__FILE__), "..", "lib" ) )

require 'stickler/middleware/gemcutter'
require 'stickler/middleware/compression'

gem_dir = File.join( File.expand_path( File.dirname( __FILE__ ) ), "..", "spec", "tmp" )

use ::Stickler::Middleware::Compression
use ::Stickler::Middleware::Gemcutter, :repo_root => gem_dir
run ::Sinatra::Base

