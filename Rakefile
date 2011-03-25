begin
  require 'bones'
rescue LoadError
  abort '### Please install the "bones" gem ###'
end

task :default => 'spec:run'
task 'gem:release' => 'spec:run'

$: << "lib"
require 'stickler/version'

Bones {
  name 'stickler'
  authors 'Jeremy Hinegardner'
  email   'jeremy@hinegardner.org'
  url     'http://www.copiousfreetime.org/projects/stickler'
  version Stickler::VERSION

  ruby_opts      %w[-W0 -rubygems]
  readme_file    'README.asciidoc'
  ignore_file    '.bnsignore'
  history_file   'HISTORY.asciidoc'

  spec.opts << "--color" << "--format documentation"

  summary 'Stickler is a tool to organize and maintain an internal gem repository.'
  description <<_
Stickler is a tool to organize and maintain an internal gem repository.
Primarily, you would want to use Stickler if:

1. You have proprietary gems that you want to have available via a gem server so 
   you may +gem install+ them.
2. You would like to have a local mirror of third party gems from either 
   http://rubygems.org or some other gem server.
3. You want both (1) and (2) in the same server.
_


  depend_on 'sinatra'    , '~> 1.2.1'
  depend_on 'addressable', '~> 2.2.4'
  depend_on 'excon'      , '~> 0.5.8'
  depend_on 'trollop'    , '~> 1.16.2'
  depend_on 'logging'    , '~> 1.5.0'

  depend_on 'bones'       , '~> 3.6.5', :development => true
  depend_on 'rack-test'   , '~> 0.5.7', :development => true
  depend_on 'bones-extras', '~> 1.3.0', :development => true
  depend_on 'builder'     , '~> 3.0.0', :development => true
  depend_on 'rspec'       , '~> 2.5.0', :development => true
}
