require 'stickler/middleware'
module Stickler::Middleware
  module Helpers
    #
    # set what, if any kind of compression to use on the response This is a Gem
    # server specific type compressions, as it does not set the http headers and
    # such in the same manner as normal compressed HTTP responses
    #
    # compression may be set to one of the following, all others will be
    # ignored.
    #
    # <b>:gzip</b>::    use Gem.gzip
    # <b>:deflate</b>:: use Gem.deflate
    # <b>nil</b>::      no compression
    #
    module Compression
      def compression=( type ) env['stickler.compression'] = type end
      def compression()        env['stickler.compression']        end
    end

    #
    # Manage the contents of the <tt>stickler.specs</tt> environment variable.
    # It is used as as communcation method between the various types of
    # middlewares managing gem repositories.  The Index server will use the
    # values in this variable in generating the responses to gem index requests
    #
    # env['stickler.specs'] is a Hash itself, the key being the return value of
    # +repo_root+ from the Class it is included in, the value for each key is
    # the Array of SpecLite's.
    #
    #
    module Specs
      #
      # The specs by repository
      #
      def specs_by_repo
        env['stickler.specs'] ||= Hash.new{ |h,k| h[k] = Array.new }
      end

      #
      # return the flattened array of all the values in
      # <tt>#specs_by_repo</tt>
      #
      def specs
        [ specs_by_repo.values ].flatten
      end

      #
      # Append spec or array of specs to the current list of specs for this key.
      #
      def append_spec( key, spec_or_array_of_specs )
        if Array === spec_or_array_of_specs then
          specs_by_repo[key].concat(  spec_or_array_of_specs )
        else
          specs_by_repo[key] << spec_or_array_of_specs
        end
      end

      #
      # Automatically append the specs from the included class into the specs
      # environment variable.
      #
      # The Class that includes this module and wants to use +append_specs+
      # MUST have a +repo+ method. The +repo+ method must +respond_to+ both
      # +repo_root+ and +specs+.
      #
      def append_specs
        append_spec( self.repo.repo_root, self.repo.specs )
      end

      #
      # Automatically append the latest_specs from the included class into the
      # specs environment variable.
      #
      # The Class that includes this module and wants to use +append_specs+ MUST
      # have a +repo+ method. The +repo+ method must +respond_to+ both
      # +repo_root+ and +specs+.
      #
      def append_latest_specs
        append_spec( self.repo.repo_root, self.repo.latest_specs )
      end
    end
  end
end
