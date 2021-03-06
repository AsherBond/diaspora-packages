#!/bin/bash
# Author : hemanth.hm@gmail.com
# Site : www.h3manth.com
# Contributions from: Mackenzie Morgan (maco) and Daniel Thomas (drt24)
# This script helps to setup diaspora.
#
#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.
# USAGE: ./pkg/ubun/tu-setup.bash  [external hostname]
# Do NOT run this script as root.
#
# Synopsis:
#   git clone http://github.com/diaspora/diaspora.git
#   cd diaspora
#   git submodule update --init pkg
#   pkg/ubuntu-setup.bash
#   ./script/server

GIT_REPO=${GIT_REPO:-'http://github.com/leamas/diaspora.git'}

arg_hostname="$1"
[ -n "$2" ] && arg_pw="password=$2"

# Set extented globbing
shopt -s extglob

# fail on error
set -e

[[ "$(whoami)" == "root" ]] && echo "Please do not run this script as root/sudo
We need to do some actions as an ordinary user. We use sudo where necessary." && exit 1

# Check if the user has sudo privileges.
sudo -v >/dev/null 2>&1 || { echo $(whoami) has no sudo privileges ; exit 1; }

# Check if universal repository is enabled
grep -ie '^deb .*universe' /etc/apt/sources.list > /dev/null || \
    { echo "Please enable universe repository" ; exit 1 ; }


# Make sure that we only install the latest version of packages
sudo apt-get update

# Check if wget is installed
test wget || { echo "Installing wget.." && sudo apt-get install wget \
    && echo "Installed wget.." ; }

# Install build tools
echo "Installing build tools.."
sudo apt-get -y --no-install-recommends install \
    build-essential libxslt1.1 libxslt1-dev libxml2
echo "..Done installing build tools"

# Install Ruby 1.8.7
echo "Installing ruby-full Ruby 1.8.7.."
sudo apt-get -y --no-install-recommends install ruby-full ruby-dev
echo "..Done installing Ruby"

# Install Rake
echo "Installing rake.."
sudo apt-get -y  --no-install-recommends install rake
echo "..Done installing rake"

#Store the release name so we can use it here and later
RELEASE=$(lsb_release -c | cut -f2)

# Get the current release and install mongodb
if [ $RELEASE == "maverick" ]
then
    #mongodb does not supply a repository for maverick yet so install
    # an older version from the ubuntu repositories
    if [ ! -f /usr/lib/libmozjs.so ]
    then
        echo "Lanchpad bug https://bugs.launchpad.net/ubuntu/+source/mongodb/+bug/557024
has not been fixed using workaround:"
        echo "sudo ln -sf /usr/lib/xulrunner-1.9.2.10/libmozjs.so /usr/lib/libmozjs.so"
        sudo ln -sf /usr/lib/xulrunner-1.9.2.10/libmozjs.so /usr/lib/libmozjs.so
    fi

    sudo apt-get -y  --no-install-recommends install mongodb
else
    lsb=$(lsb_release -rs)
    ver=${lsb//.+(0)/.}
    repo="deb http://downloads.mongodb.org/distros/ubuntu ${ver} 10gen"
    echo "Setting up MongoDB.."
    echo "."
    echo ${repo} | sudo tee -a /etc/apt/sources.list
    echo "."
    echo "Fetching keys.."
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
    echo "."
    sudo apt-get  update
    echo "."
    sudo apt-get -y  --no-install-recommends install mongodb-stable
    echo "Done installing monngodb-stable.."
fi

# Install imagemagick
echo "Installing imagemagick.."
sudo apt-get -y --no-install-recommends install imagemagick libmagick9-dev
echo "Installed imagemagick.."

# Install java (jammit implicit requirement)
echo "Installing java.."
sudo apt-get -y --no-install-recommends install openjdk-6-jre-headless
echo "Installed java.."

# Install git-core
echo "Installing git-core.."
sudo apt-get -y --no-install-recommends install git-core
echo "Installed git-core.."

# Instal libssl-dev (rumour dependency)
sudo apt-get -y --no-install-recommends install libssl-dev

echo "Installing redis server"
sudo apt-get -y --no-install-recommends install redis-server

# Setting up ruby gems
echo "Fetching and installing ruby gems.."
(
    if [ $RELEASE == "maverick" ]
    then
        sudo apt-get install --no-install-recommends -y rubygems
        sudo ln -sf /var/lib/gems/1.8/bin/bundle /usr/local/bin/bundle #for PATH
    elif [ $RELEASE == "lucid" ]
    then
        sudo add-apt-repository ppa:maco.m/ruby
        sudo apt-get update
        sudo apt-get install --no-install-recommends -y rubygems
        sudo ln -sf /var/lib/gems/1.8/bin/bundle /usr/local/bin/bundle #for PATH
    else
        # Old version
        echo "."
        cd /tmp
        wget http://production.cf.rubygems.org/rubygems/rubygems-1.3.7.tgz
        echo "."
        tar -xf rubygems-1.3.7.tgz
        echo "."
        cd rubygems-1.3.7
        echo "."
        sudo ruby setup.rb
        echo "."
        sudo ln -sf /usr/bin/gem1.8 /usr/bin/gem
        echo "."
    fi
)
echo "Done installing the gems.."

# Install bundler
echo "Installing bundler.."
sudo gem install bundler
echo "Installed bundler.."

# Take a clone of Diaspora
# Check if the user is already in a cloned source if not clone the source
[[ $( basename $PWD ) == "diaspora" ]]  && \
    echo "Already in diaspora directory" ||  {
        git clone $GIT_REPO && {
            cd diaspora
            git submodule update --init pkg
            echo "Cloned the source.."
        }
    }

# Install extra gems
echo "Installing more gems.."
bundle install || {
    echo "OOPS: bundle install crashed. Let's try once again!"
    bundle install
}
#    bundle exec jasmine init
[ -e lib/tasks/jasmine.rake ] && \
    mv lib/tasks/jasmine.rake lib/tasks/jasmine.no-rake &&
        touch lib/tasks/jasmine.rake
echo "Installed."

#Configure diaspora
cp config/app_config.yml.example config/app_config.yml
hostname=$( awk '/pod_url:/ { print $2; exit }' <config/app_config.yml)

if [ -n "$arg_hostname" ]; then
    sed -i "/pod_url:/s|$hostname|$arg_hostname|g" config/app_config.yml &&
    echo "config/app_config.yml updated."
else
    while : ; do
        echo "Current hostname is \"$hostname\""
        echo -n "Enter new hostname [$hostname] :"
        read new_hostname garbage
        echo -n "Use \"$new_hostname\" as pod_url (Yes/No) [Yes]? :"
        read yesno garbage
        [ "${yesno:0:1}" = 'y' -o "${yesno:0:1}" = 'Y' -o -z "$yesno" ] && {
            sed -i "/pod_url:/s|$hostname|$new_hostname|g" \
                config/app_config.yml &&
            echo "config/app_config.yml updated."
            break
        }
    done
fi

# Install DB setup
echo "Setting up DB..."
rake db:first_user $arg_pw || {
    cat <<- EOF
	Database config failed. You might want to:
	 - Check that mongod is running: service mongodb status
	 - Repair database files: mongod --repair
	 - Remove all db files: rm -rf /var/lib/mongodb/*
	 - Reset the config file by
	     'cp config/app_config.yml.example config/app_config.yml'
	before making a new try.
	EOF
}

echo 'To start server: sudo su - diaspora -c "diaspora/script/server -d"'
echo "To stop server: pkill thin; kill \$(cat $pidfile)"

