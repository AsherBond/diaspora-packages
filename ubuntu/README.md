## Package-oriented install for ubuntu.

Here are  scripts to install diaspora on Ubuntu. They are designed to
work as a first step towards packaging, but should be usable as is.

### Synopsis

Bootstrap the distribution from git:
    % sudo apt-get install git-core
    % git clone git://github.com/diaspora/diaspora.git
    % cd diaspora
    % git submodule update --init pkg

Create and install the diaspora bundle and application in
diaspora/pkg/source according to
[source README]
(http://github.com/diaspora/diaspora-packages/tree/master/source/):
    % cd pkg/source
    % ./make-dist.sh bundle
    % ./make-dist.sh source

Install the dependencies (a good time for a coffe break):
    % cd ../ubuntu
    % sudo ./diaspora-install-deps

Install and  initiate the tarballs created by make-dist.sh:
    % sudo ./diaspora-install-bundle \
        dist/diaspora-bundle-rt-0.0-xxxx_yyyy.tar.gz
    % sudo ./diaspora-install dist/diaspora-0.0-xxxx_yyyy.tar.gz
    % sudo ./diaspora-setup

Start the development server
    % sudo su - diaspora
    % cd /usr/share/diaspora/master
    % ./script/server

Start servers
    % sudo service diaspora start

### Upgrading

The normal procedure to update is to just
    $ sudo su - diaspora
    $ cd /usr/share/diaspora/master/pkg/ubuntu
    $ ./make-dist.sh bundle
    $ ./make-dist.sh source

and then use diaspora-install and diaspora-install-bundle as above.
It's necessary to always have the correct bundle. The  *./make-dist.sh bundle*
above will use a cached bundle if it's still valid, else build a new.
In most cases only source will need to be built, which is fast.

### Notes

The diaspora services are controlled by upstart. To start/stop
individual services:
    % sudo initctl <start|stop|status>  diaspora-thin
    % sudo initctl <start|stop|status>  diaspora-redis
    % sudo initctl <start|stop|status>  diaspora-websocket
    % sudo initctl <start|stop|status>  diaspora-resque

The application lives in /usr/share/diaspora/master. All writable areas
(log, uploads, tmp) are links to /var/lib/diaspora. The config file lives
in /etc/diaspora. All files in /usr/share are read-only, owned by root.

The bundle lives in /usr/lib[64]/diaspora-bundle, readonly, owned by root.
Application finds it through the symlinked *vendor* directory.

Once diaspora is installed, makedist.sh et. al. are available in
/usr/share/diaspora/master/pkg/ubuntu, so there's no need to checkout
the stuff using git in this case.

The user diaspora is added during install.

Tools used for building package are installed globally. All of diasporas
dependencies lives in the application - nothing is installed by user or
on system level.

This has been tested on a Ubuntu 32-bit 10.10 , clean server and on 10.04
Lucid desktop, also clean installation. Irregular nightly builds are
available from time to time at
[ftp://mumin.dnsalias.net/pub/leamas/diaspora/builds](ftp://mumin.dnsalias.net/pub/leamas/diaspora/builds)

mongodb is having problems occasionally. Sometimes the dependencies are not
installed, and mongod refuses to start. invoke */usr/bin/mongod -f
/etc/mongodb.conf* to test. The lockfile /var/lib/mongodb/mongod.lock is
also a potential problem. Remove to make it start again.
