#!/bin/bash
#
#  Install diaspora and  its dependencies.
#
#  Usage: pkg/bootstrap-fedora-diaspora.sh [external hostname]
#
#  Synopsis, install:
#      $ git clone git@github.com:diaspora/diaspora-packages.git
#      $ cd diaspora-packages
#      $ sudo diaspora-packages/fedora14-setup.sh
#      $ sudo su - diaspora -c "diaspora/script/server -d"
#
#  A new diaspora clone is place in ~diaspora.
#  This dir is populated, configured and finally
#  acts as a base for running diaspora servers.
#
#  Script is designed not to make any changes in invoking
#  caller's environment.
#
#  Must run as root

GIT_REPO=${GIT_REPO:-'http://github.com/diaspora/diaspora.git'}
DIASPORA_HOSTNAME=${1:-$(hostname)}
PASSWORD=${2:-'nosecret'}

test $UID = "0" || {
    echo "You need to be root to do this, giving up"
    exit 2
}

echo "Installing diaspora from $GIT_REPO"

sudo yum groupinstall -y "Development tools"

yum install  -y  \
    compat-readline5         \
    git java-1.6.0-openjdk   \
    ImageMagick              \
    libffi-devel             \
    libxml2-devel            \
    libxslt-devel            \
    libyaml-devel            \
    mongodb-server wget      \
    openssl-devel            \
    readline-devel           \
    ruby-devel               \
    ruby-irb                 \
    ruby-libs                \
    ruby-rdoc                \
    ruby-ri                  \
    rubygems                 \
    sqlite-devel             \
    zlib-devel

sudo gem install bundler

getent group diaspora  >/dev/null || groupadd diaspora
getent passwd diaspora  >/dev/null || {
    useradd -g diaspora -s /bin/bash -m diaspora
    echo "Created user diaspora"
}

service mongod start

su - diaspora << EOF
#set -x #used by test scripts, keep

[ -e  diaspora ] && {
    echo "Moving existing  diaspora out of the way to diaspora.$$"
    mv  diaspora  diaspora.$$
}

git clone $GIT_REPO
cd diaspora
git submodule update --init pkg

rm -rf .bundle

bundle install --path vendor/bundle
#bundle exec jasmine init

#Configure diaspora
cp config/app_config.yml.example config/app_config.yml
source pkg/source/funcs.sh
init_appconfig config/app_config.yml "$DIASPORA_HOSTNAME"
mv lib/tasks/jasmine.rake lib/tasks/jasmine.no-rake

echo "Setting up DB..."
if  bundle exec rake db:first_user  password=$PASSWORD; then
    echo "DB config OK,  first user created"
else
    cat <<- EOM
	Database config failed. You might want to remove all db files with
	'rm -rf /var/lib/mongodb/*' and/or reset the config file by
	'cp config/app_config.yml.example config/app_config.yml' before
	making a new try. Also, make sure the mongodb server is running
	e. g., by running 'service mongodb status'.
	EOM
fi

echo 'To start server: sudo su - diaspora -c "diaspora/script/server -d"'
echo " To stop server: pkill thin; kill \$(cat $pidfile)"

EOF


