#-----------------------------------------------------------------------
# Example rackup file for an entire stickler stack
#-----------------------------------------------------------------------
$:.unshift File.expand_path( File.join( File.dirname(__FILE__), "..", "lib" ) )

require 'stickler/web'

use Stickler::Web
run Sinatra::Base
