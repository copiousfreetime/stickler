require 'rubygems'
require 'stickler/repository/rubygems_authenticator'

module Stickler
  class Client
    class ConfigFile
      def initalize
        @updated = false
      end

      def config_path
        File.join(Gem.user_home, '.gem', 'stickler')
      end

      def configuration
        Gem.configuration.load_file(config_path)
      end

      def update( opts )
        self.server   = opts[:server]   if opts[:server]
        self.upstream = opts[:upstream] if opts[:upstream]
        return updated?
      end

      def updated?
        return @updated
      end

      def server
        configuration[:server]
      end

      def server=( server )
        config = configuration.merge( :server => server )
        save_config( config )
      end

      def upstream
        configuration[:upstream] || ::Stickler::Repository::RubygemsAuthenticator.rubygems_uri.to_s
      end

      def upstream=( upstream )
        config = configuration.merge( :upstream => upstream )
        save_config( config )
      end

      def save_config( config )
        dirname = File.dirname(config_path)
        Dir.mkdir(dirname) unless File.exists?(dirname)

        File.open(config_path, "w") do |f|
          f.write config.to_yaml
        end
        @updated = true
      end
    end
  end
end
