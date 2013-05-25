#!/bin/sh

echo 'Rails...'

which rails >/dev/null && echo 'Already installed!' && exit 0;

./setup_mysql_client.sh  || exit -1

REQUIRED_PACKAGES="\
    ruby-1.8.7.352-7.el6_2                      \
    ruby-devel-1.8.7.352-7.el6_2                \
    compat-readline5-5.2-17.1.el6               \
    ruby-libs-1.8.7.352-7.el6_2                 \
    rubygems-1.3.7-1.el6                        \
    ruby-irb-1.8.7.352-7.el6_2                  \
    ruby-rdoc-1.8.7.352-7.el6_2                 \
    "
sudo yum install -y $REQUIRED_PACKAGES || exit -1

./setup_buildtools.sh || exit -1	# needed for some native rubygems

# put some gems first ..
sudo gem install rake -v 0.8.7 --no-rdoc --no-ri --ignore-dependencies || exit -1

sudo gem install abstract -v 1.0.0 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install actionmailer -v 2.3.10 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install actionmailer -v 2.3.9 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install actionmailer -v 2.3.8 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install actionpack -v 2.3.10 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install actionpack -v 2.3.9 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install actionpack -v 2.3.8 --no-rdoc --no-ri --ignore-dependencies || exit -1
#sudo gem install activemodel -v 3.0.3 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install activerecord -v 2.3.10 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install activerecord -v 2.3.9 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install activerecord -v 2.3.8 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install activeresource -v 2.3.10 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install activeresource -v 2.3.9 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install activeresource -v 2.3.8 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install activesupport -v 2.3.10 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install activesupport -v 2.3.9 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install activesupport -v 2.3.8 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install addressable -v 2.2.6 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install arel -v 2.0.4 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install aws-s3 -v 0.6.2 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install bluecloth -v 2.0.9 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install BlueCloth -v 1.0.1 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install builder -v 2.1.2 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install bundler -v 1.0.7 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install cgi_multipart_eof_fix -v 2.5.0 --no-rdoc --no-ri --ignore-dependencies || exit -1
#sudo gem install cheddargetter_client_ruby -v 0.3.1 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install columnize -v 0.3.2 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install crack -v 0.1.8 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install daemon_controller -v 0.2.5 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install daemons -v 1.1.0 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install erubis -v 2.6.6 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install fastthread -v 1.0.7 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install ffi -v 0.6.3 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install file-tail -v 1.0.5 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install gem_plugin -v 0.2.3 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install gemcutter -v 0.7.0 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install hobo -v 1.0.2 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install hobofields -v 1.0.2 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install hobosupport -v 1.0.2 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install httparty -v 0.7.7 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install i18n -v 0.4.2 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install linecache -v 0.43 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install mail -v 2.2.10 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install mime-types -v 1.16 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install mongrel -v 1.1.5 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install mysql -v 2.8.1 --no-rdoc --no-ri --ignore-dependencies || exit -1
#sudo gem install nokogiri -v 1.4.4 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install passenger -v 3.0.0 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install polyglot -v 0.3.1 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install rack -v 1.1.0 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install rack -v 1.2.1 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install rack-mount -v 0.6.13 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install rack-test -v 0.5.6 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install rails -v 2.3.8 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install railties -v 3.0.3 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install recurly -v 0.4.7 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install ruby-debug -v 0.10.4 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install ruby-debug-base -v 0.10.4 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install rubygems-update -v 1.3.7 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install sass -v 3.1.7 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install spruz -v 0.2.2 --no-rdoc --no-ri --ignore-dependencies || exit -1
#sudo gem install sqlite3-ruby -v 1.3.2 --no-rdoc --no-ri --ignore-dependencies || exit -1 -- needs sqlite3-devel
sudo gem install thor -v 0.14.6 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install treetop -v 1.4.9 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install tzinfo -v 0.3.23 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install will_paginate -v 2.3.15 --no-rdoc --no-ri --ignore-dependencies || exit -1
sudo gem install xml-simple -v 1.0.15 --no-rdoc --no-ri --ignore-dependencies || exit -1

# -- later when accounts is migrated
#cd $HOME/gits/clouds/gen/rails/my/public
#make    # make gen.min.js

ln -s /home/br/gits/clouds/gen/rails/my/log /var/log/br/rails_my
ln -s /home/br/gits/clouds/gen/rails/netops/log /var/log/br/rails_netops

exit 0

