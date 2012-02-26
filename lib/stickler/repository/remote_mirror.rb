require 'stickler/repository/remote'
module ::Stickler::Repository
  #
  # A Repository::Api implementation that retrieves all is data from an HTTP
  # based remote location.  It utilizes the Modern gem server api and the gem
  # cutter api (push/yank/unyank).  The legacy gem server api is not utilized.
  #
  # This also supports the single extra method #mirror which tells the remote
  # mirror repostory to mirro the given gem from an upstream server.
  #
  class RemoteMirror < Remote
    # Tell the remote repoistory to mirror the given gem from an upstream
    # repository
    def mirror( spec, upstream_host )
      raise Stickler::Repository::Error, "gem #{spec.full_name} already exists in remote repository" if remote_gem_file_exist?( spec )
      resp = resource_request( mirror_resource( spec, upstream_host ) )
    end

    private

    def mirror_uri( spec, upstream_host )
      [ uri.join( upstream_host ), spec.name, spec.version.to_s, spec.platform].join("/")
    end

    def mirror_resource( spec, upstream_host )
      muri   = mirror_uri( spec, upstream_host )
      params = { :method => :post, :expects => [200, 201] }
      Excon.new( muri.to_s, params )
    end
  end
end
