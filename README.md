# Stickler

* [Homepage](http://github.com/copiousfreetime/stickler)
* [GitHub](http://github.com/copiousfreetime/stickler)
* email jeremy at copiousfreetime dot org
* `git clone git://github.com/copiousfreetime/stickler.git`

## DESCRIPTION

Stickler is a tool to organize and maintain an internal gem repository.
Primarily, you would want to use Stickler if:

1. You have proprietary gems that you want to have available via a gem server so 
   you may `gem install` them.
2. You would like to have a local mirror of third party gems from either 
   http://rubygems.org or some other gem server.
3. You want both (1) and (2) in the same server.


## INSTALLATION

Installing stickler may be done via the standard gem installation

    gem install stickler

Or downloaded from http://github.com/copiousfreetime/stickler/downloads


## USAGE

Stickler is broken up into a few commandline programs.

* **stickler** - Used to mainpulate gems that are in a stickler-server.
* **stickler-server** - The server process that manages gems.
* **stickler-passenger-config** - A helper process to generate Passenger configurations for

The easiest way to get up and running with stickler is to run the standalone
server `stickler-server` and then use `stickler` to interact with it.

### Start up a standalone stickler server

    % mkdir -p /tmp/stickler-test
    % stickler-server start --daemonize /tmp/stickler-test

### Set some sane defaults

    % stickler config --add --server http://localhost:6789 --upstream https://rubygems.org
      server : http://localhost:6789
    upstream : https://rubygems.org

    % cat ~/.gem/stickler
    ---
    :server: http://localhost:6789
    :upstream: https://rubygems.org

### Take a few gems and push them to the server

    % ls -1
    heel-2.0.0.gem
    hitimes-1.1.1.gem
    launchy-0.3.5.gem
    stickler-2.0.0.gem

    % stickler push *.gem
    Pushing gem(s) to http://localhost:6789/ ...
      /Users/jeremy/tmp/gems/heel-2.0.0.gem     -> OK http://localhost:6789/gems/heel-2.0.0.gem
      /Users/jeremy/tmp/gems/hitimes-1.1.1.gem  -> OK http://localhost:6789/gems/hitimes-1.1.1.gem
      /Users/jeremy/tmp/gems/launchy-0.3.5.gem  -> OK http://localhost:6789/gems/launchy-0.3.5.gem
      /Users/jeremy/tmp/gems/stickler-2.0.0.gem -> OK http://localhost:6789/gems/stickler-2.0.0.gem

### Mirror a gem from upstream

    % stickler mirror --gem-version 1.4.3 logging
    Asking http://localhost:6789/ to mirror logging-1.4.3 from rubygems.org : OK -> http://localhost:6789/gems/logging-1.4.3.gem
    % stickler mirror --gem-version 1.16.2 trollop
    Asking http://localhost:6789/ to mirror trollop-1.16.2 from rubygems.org : OK -> http://localhost:6789/gems/trollop-1.16.2.gem

### Look at all the gems installed in your stickler server

Open your browser to http://localhost:6789

    % launchy http://localhost:6789

### Install a gem from your new stickler gem server

    % gem install hitimes --source http://localhost:6789/

### Configure your servers to globally use your internal stickler gem server

    % cat /etc/gemrc
    ---
    :benchmark: false
    :verbose: false
    :update_sources: true
    :bulk_threshold: 1000
    :backtrace: false
    :sources:
    - http://stickler.example.com
    gem: --no-rdoc --no-ri

## See Also

The man pages that ship with the gem.  They may be viewed if you also install
the [gem-man](http://defunkt.github.com/gem-man/) gem.

    % gem install gem-man
    % gem man stickler
    View which manual?
     1. stickler-passenger-config(1)
     2. stickler-server(1)
     3. stickler(1)
    >

## DEVELOPMENT

If you want to do development on stickler, please see
[CONTRIBUTING.md](./CONTRIBUTING.md)


## CREDITS

* [The Rubygems Team](https://github.com/rubygems/rubygems)


## LICENSE

Copyright (C) 2008-2013 Jeremy Hinegardner ISC License, See [LICENSE](./LICENSE) for details.

