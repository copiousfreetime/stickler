#--
# Copyright (c) 2008 Jeremy Hinegardner
# All rights reserved.  Licensed under the same terms as Ruby.  No warranty is
# provided.  See LICENSE and COPYING for details.
#++

module Stickler 

  # Paths module used by all the other modules and classes for
  # determining paths and default values.
  #
  module Paths

    #
    # The root directory of the project is considered to be the parent directory
    # of the 'lib' directory.  returns the full expanded path of the parent
    # directory of 'lib' going up the path from the current file.  A trailing
    # File::SEPARATOR is guaranteed.
    #
    def self.root_dir
      unless @root_dir
        path_parts = ::File.expand_path(__FILE__).split(::File::SEPARATOR)
        lib_index  = path_parts.rindex("lib")
        @root_dir = path_parts[0...lib_index].join(::File::SEPARATOR) + ::File::SEPARATOR
      end
      return @root_dir
    end

    # 
    # return the full expanded path of the +config+ directory below +root_dir+.
    # All parameters passed in are joined on to the result. a Trailing
    # File::SEPARATOR is guaranteed if _args_ are *not* present
    #
    def self.config_path(*args)
      self.sub_path("config", *args)
    end

    #
    # return the full expanded path of the +data+ directory below +root_dir+.
    # All parameters passed in are joined on to the result. a Trailing
    # File::SEPARATOR is guaranteed if _args_ are *not* present
    #
    def self.data_path(*args)
      self.sub_path("data", *args)
    end
   
    #
    # return the full expanded path of the +lib+ directory below +root_dir+.
    # All parameters passed in are joined on to the result. a Trailing
    # File::SEPARATOR is guaranteed if _args_ are *not* present
    #
    def self.lib_path(*args)
      self.sub_path("lib", *args)
    end

    private
    def self.sub_path(sub,*args)
      sp = ::File.join(root_dir, sub) + File::SEPARATOR
      sp = ::File.join(sp, *args) if args
    end
  end
end
