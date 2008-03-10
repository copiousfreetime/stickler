#--
# Copyright (c) 2008 Jeremy Hinegardner
# All rights reserved.  Licensed under the same terms as Ruby.  No warranty is
# provided.  See LICENSE and COPYING for details.
#++

require 'main'
require 'stickler/version'

module Stickler
  CLI = ::Main.create {
      option('directory') { description 'the stickler directory' }

      def run 
        puts "Rolling...."
      end

      mode 'setup' do
        option('force') { description 'SMASH!' }
        def run 
          puts "Running setup"
        end
      end

      mode 'add' do
        argument('gem or directory') { description 'what do you want to add?' }
      end
  }
end
