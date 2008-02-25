#--
# Copyright (c) 2008 Jeremy Hinegardner
# All rights reserved.  Licensed under the same terms as Ruby.  No warranty is
# provided.  See LICENSE and COPYING for details.
#++
#
module Stickler

  # Version access in every possibly way that people might want to get it.
  #
  module Version

    MAJOR = 0
    MINOR = 0
    BUILD = 1

    def self.to_ary
      [MAJOR, MINOR, BUILD]
    end

    def self.to_s
      self.to_ary.join(".")
    end

    def self.to_hash
      { :major => MAJOR, :minor => MINOR, :build => BUILD }
    end
    
  end

  VERSION = Version.to_s
end
