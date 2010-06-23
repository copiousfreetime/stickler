require 'stickler/repository'
module Stickler::Repository
  #
  # The API that all Stickler Repository classes MUST implement.  
  # This file is here to document the API
  #
  module Api

    #
    # The list of methods in the api
    #
    def self.methods
      %w[ gem_path specification_path source_index search_for push add_gem ]
    end

    #
    # Return the path to where all the .gem file are stored in the repository
    #
    def gem_path
      raise NotImplementedError, not_implemented_msg( :gem_path )
    end

    #
    # Return the path to where all the .gemspec file are stored in the repository
    #
    def specification_path
      raise NotImplementedError, not_implemented_msg( :specification_path )
    end

    #
    # Return a GemSourceIndex object that can be used to query the 
    # repository
    #
    def source_index
      raise NotImplementedError, not_implemented_msg( :source_index )
    end

    # 
    # given something that responds to :name, :version, :platform, 
    # then search for all specs that match 
    #
    def search_for
      raise NotImplementedError, not_implemented_msg( :search_for )
    end

    def push
      raise NotImplementedError, not_implemented_msg( :push )
    end
    
    def add_gem
      raise NotImplementedError, not_implemented_msg( :add_gem )
    end

    private
    # :stopdoc:
    def not_implemented_msg( method )
      "Please implement #{self.class.name}##{method}"
    end
    # :startdoc:
  end
end
