#!/bin/bash
#

# Get some variables
echo -n " Please enter an instance name: "
read instance_name
echo -n " Please enter a dev linux username: "
read dev_user
echo -n " Please enter a dev author name: "
read author_name
echo -n " Please enter a dev author address: "
read author_email
echo -n " Please enter your bugzilla password: "
read bugz_pass

echo deb http://ftp.indexdata.dk/debian wheezy main | tee /etc/apt/sources.list.d/koha.list
wget -O- http://ftp.indexdata.dk/debian/indexdata.asc | apt-key add -
echo deb http://debian.koha-community.org/koha squeeze-dev main >> /etc/apt/sources.list.d/koha.list
wget -O- http://debian.koha-community.org/koha/gpg.asc | apt-key add -

# Install Vim
yes | aptitude install vim-nox && yes | aptitude purge nano
sed -i "s/\"syntax on/syntax on/" /etc/vim/vimrc

# Install Sudo
yes | aptitude install sudo
echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/sudo

# Install cpanm
yes | aptitude install cpanminus

# Install Koha
aptitude update && aptitude install koha-common mysql-server && aptitude full-upgrade

cat > /etc/koha/koha-sites.conf <<EOL
DOMAIN=".koha-ptfs.co.uk"                     # Any library instance will be a subdomain of this string.
INTRAPORT="80"                                # TCP listening port for the administration interface
INTRAPREFIX=""                                # For administration interface URL: Prefix to be added to the instance name.
INTRASUFFIX="-staff"                          # For administration interface URL: Suffix to be added to the instance name.
DEFAULTSQL="/usr/share/koha/defaults.sql.gz"  # only needed if you are pre-populating from another Koha database
OPACPORT="80"                                 # TCP listening port for the users' interface (if you skip this, the apache default of 80 will be used)
OPACPREFIX=""                                 # For users' interface URL: Prefix to be added to the instance name.
OPACSUFFIX=""                                 # For users' interface URL: Suffix to be added to the instance name.
ZEBRA_MARC_FORMAT="marc21"                    # Specifies format of MARC records to be indexed by Zebra. Possible values are "marc21", "normarc" and "unimarc"
ZEBRA_LANGUAGE="en"                           # Primary language for Zebra indexing. Possible values are 'en', 'fr' and 'nb'
EOL

a2enmod rewrite
a2dissite default
service apache2 restart

# Set MySQL Defaults
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -uroot -p'melB1n' mysql
printf "[mysqld]\ninit_connect='SET collation_connection = utf8mb4_unicode_ci'\ncharacter-set-server = utf8mb4\ncollation-server = utf8mb4_unicode_ci\n\n[client]\ndefault-character-set = utf8mb4\n\n[mysql]\ndefault-character-set = utf8mb4\n" | tee /etc/mysql/conf.d/mysqld_utf8.cnf
service mysql restart

koha-create --create-db "$instance_name"

# Install Git
yes | aptitude install git git-email 

# Add Dev User
adduser "$dev_user"
usermod -aG sudo "$dev_user"
usermod -aG koha_"$instance_name" "$dev_user"
mkdir /home/"$dev_user"/.ssh
ssh-keygen -f /home/"$dev_user"/.ssh/id_rsa
printf "# PTFS Staff Keys\nssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAz72/+nNqVPb+k0R5Iim0gljclP2TK5Mfh0SA/ob+TP9EI2rKvVStGMDilAO3ZQB+1DVjC92UmPf0vnkYjdFejZXx/Kd/xUVRJHVyXypidiW9yOvC12IUOFP35h3q0ff5XZYO7qNmNGAoomZCDT0e8tcF0trceEW5wMKI++V5UAzU1zbnH6k6hTYOGxv+SVUAHWAxdnhVxzFRfv65VOcJzXUGAIS0MZd/OTafdW8pPRhKz+IxW6uAagxhv0FUlXfv9i5mVXeRqpOZw1mtlTtIgvRNHwMlR2dQapRd83A0EKQx/tNCbmuMrYhzB7ZxBh2e3T5WJkpb00sbNg44Fd12PQ== colin.campbell@ptfs-europe.com\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDWch2IKomS5BfC/iy3X84y5LR4PyNPO8ViEnm3Z5zVrXjDTlylmv7N1C7whbl+fpVwoVYWEutaT86xycyRKhrcSm96UuB7g1q8B3PRuPBWJzA7aA50/Pe0oeM7HdGVkUpSe1/pjP46l5JKi0E4VYpi9OQAWIyrU/vk/MZewS3qcKYjMxAqKYZPn9Dhd+6Szg3JOm+r+oFoVGOXA7Cfrs0B9BHv6xU3wEbOWS5aEj8bLhbihsj47pZ50HZj88SydZQfFFbBZ6dEGjxnoEFtuMedBqbd+VIWQHZnBZ9H6/lvs+KKuSNYUzhAkjOiDUdWwDu+6laU/ODvL3EJBVVo0/ID colin.campbell@ptfs-europe.com\nssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQBWZ+rmtqQfQmG8gwzmtHzjJh4otdOuBBrH0kW3TNPJPehBn/RlPD6L8Kxwo5+IyuQQgOnqjWZatr87HT/XfFkCo1TQVRNILL6knf8tw0SZqzjrwzWWZjXuCjniCVG/Vj6DT8FkUldZogzTRjDcEIYCYtF/eBUPXZtqtGlaK96U3ORb0T1CuMt7eivg9sIhOLMfx36N1MoyufBbgEhGbYy/an8EIzUg3p2lQDboEheipnqwheKHLGilB00A43To1ltnx8Ey38diUE75lPERd0DMWoVl0BOo4k1rTrL8h7dxmRiStUNVwZ5qOrTktFt1F6rbnqwvCf5K0v2gHf7AFLOz ian.bays@ptfs-europe.com\nssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIBdBRF5ju7KPmjW7YzWwPBUxAU75nPolAGbdjytRJ8yXHliW/DBwdJ1BhAwrpthclhb8gMU/CfWZ26d0ypfGZiJK8EMr8k1aK3FlxHtVJM7Il2kBeev2gDQWyUWFzThnkf2DRLgI0N0R4ekgYgHX6XtwGZAhI0DjOwycvc1cTllIw== janet.mcgowan@ptfs-europe.com\nssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAl37dh3JBwKuUS1faWcIkFG3UYuRcDA83Q5iHa7YkvsbivJv59l2/UmcuIpX4Hac+4Spq5jHCpk6bHs/TkMfeoVbTuv/HFC4EkTtZl9sNTtfvXg/DTv1oLWXL2200NLxGXgbq+JMFtHx0Oypfv53ghHggrWepJFE6tyc+0RamelM= jonathan.field@ptfs-europe.com\nssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAyL9FZ/uaEmt2bLjwfW9WVRC5uN8pNQXbZTYJZx0u0IBiDecZc4NBcaY+YWSar3QINn7uBGGeEbYGgLRQF7KdxZD1YaNtyUl6J8AIjcPfQR0KFuxpzOoXWUlrrcDIoCsJ9Bn7kcsr9oUtjcTkrRxT8voYDRqxIjkBLErevXFb0+Pq7g57v0DOgz3Znpnp4oR1OFoTX2K0UGtgha3kztCowkuaIGwz8XmzZxIxng0wlXVounZUEzlhPx/EMZFp7XQEOte8YvC2+vXzPq5pa3IHasRFA7gn4dAyHvTFGKlOy2jgFuAigQUWyebRgxIjiHWvpMptYpLNlZXSndSUi9Jvrw== mark.gavillet@ptfs-europe.com\nssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAwErM7MIrv84HbQC9DzvH5C5gODffe5eNkR+1qQcD0TAZuGVtd7m19ezB1MZoSd91M6VsL0dI36PmHx08ScBWj7FifAhDV5PEw7GUPF0y2ynFgUDUctSZCAAEllRfkHmeTZNfYpkj4VGhmepLQCh1DJUDjvQHMh08FjLqngLgud4Yl5RxJDzG6m4lvpKER2ljLw4TwoNs1OyLh9Lu5cAkuIGcIxvHXibo1LMHFDhYSwBFLzIBLePQX16QjDs0Fn66N/0KCBZoRo0lvPZoaMbWsfRA04VNrFspzBHs6VtBRGPBdkQh0lN2o8dCQGFNTw1MUJ1SHFfURLk2cDQThNrOdw== mark.gavillet@gmail.com\nssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQB+plB1H8ZDRQnpR9eU+bEKAOJqBvS7p3k3Btcg2bCkmChHnppsYZMuE8vBKUjjcI0cirlpKmoJSQwMNgl1mFgTFzwwkwbeGhx3mseQAGcqlav++LYf0YpPPoLKObPREf0u7KGTc749h0EtdAjaG+zsxLrlVd4KueId4X3XD35cJJAqn0x3ifP7zTp8eRqNPko4tCiqB6PN+SALqfhWv/ALMUBFhyEe9j9z8gVTSGzg3VxHjdhMFc48tnxsL5EOCWWI3O8y/h0/eAofK70u56GLDIZlPJfTxZkl4Sl/gosqGufN3kpKRLID2ycMHHfULxa8rOTwROqy9PZtj4x6itAF martin.renvoize@ptfs-europe.com\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl4rWSUHIR74pWxdrSNdoAadq+2Uqoy93kKJpIz1RdYZSAiNTvyYN5mLwZASfX9mGExDV4Y4XFHCz5BG4c0pcQQ/bhkZQhIpUbp8T5jLXEvqAOfdjKFQztJ6RuIdJhF5FQydjWj6XRYU8SVrq/ELNFKeMjFMehFeO3b9rS8aunXXrAg/mjRLqsc9WWH2bqfmL41/c5FcYvQytUP/Wvu8GMUnyw/CSKLQaKTctKwz1TcQiNMmiSR2ickRDnet3VEyBcCeaiSzKZg4HJ+CFF4ApfX7VJyKRhg1B5dFL5KOVBUja0tgn4H1CTtCMW8QOVUV7aqbq+fsoWTDfoME6+cmJ3 martin.renvoize@ptfs-europe.com\nssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIBzLvA+54KRormQMcwBOGEZG9yjojKm880iAHsUw4CA56z8lJwfKmC7uct2M7mYM4yxnonbryKQD5lhffvPT63dJLaMKe/RJDAquiKKXGZcCWOcaxHT2m/5A12+dfTaguxj6sUlUNdAzFvQbkvWiNJyYcTfFzZiquQd0K+wIeWqXw== fiona.borthwick@ptfs-europe.com\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCjTe6eZBalDrMAbs/BYvjZfgdQ6xbtjH/GkZrJdkU/A2W8+9Uw78e9RFOaJF2ZCmvQCtID6uXCDCEKha97aVUhZibBira+gRoAFfAdO7eKQUVuZ6qKVi4zaEuhPUugDTCf4+2/DHGo/j+k5bg3+rHUSIjGmWDi/NJyR0vQ2JxSlG6MBO22H9SX2LlaZYVC2EKRY/PBjbEPUDd1fw8eNR3jULkRXiP/R9vgIKll8rQnqsLaoY6+NRjrKzIdhKGA+y5M9I5eeuRsji+B0WFKkb4qIa2LGERx06+LkYAYJhcbb+0wjgROWxFj7yYBPV+Gcar9wtVmfTU3UuUH+hvhm19L Ian HTC\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0hZIQxl4lDPvK1WvcnjQwqOOObGISUso0STnVmm5wgcqx+l/Q6UODXjEqucc0EQfO4UJ57gSM1dVCinZiz03z8vjKe8FtjMTAV3y6y9PDVOCpcITx2gDRSYRjsY9d7tFD0+yoJGI/nykca/ibbDwyM1+We1BbwVv3LF/BuA5LViVYzwdD9FcOx1XSoWc8tJ7OzMg3dExdOC88adwAg767oqS7/B6X7OYhPjnWbcOLA4c9r1a5RDcTLaJRr4H5lYDio6OHjblxUQIhWv8Dg+FUpssHiUIuS+KQ4KrWV/l0qcfIrXo8EFW34vjUkEbRsTCSgJQW6U79OdNXnNOYHOux martin.renvoize@ptfs-europe.com\nssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAhVl6+6gbVYOi7klUFHhuGjMNxnafsEm/hNQ2IVNlqUODzKsiZOI3925jJ1YMZf2TJLOTuBBbezF3KrxtFg+aM0YgWYFA7oC95mH/KfP6LFh8188khj7oNy89L4Fdt9O8JdnsF6Man88avcFBEnbQ76B3svks9PNJ3jAHwW3rhEU= fiona.borthwick@ptfs-europe.com\n# Update Key\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCtonB9hv8Xwz/T4wwf4NXpDHtC6x7skXAUmkfIDjHjqHn2PvmvM8iokO3Vw4Yacqdn3lTAhVMSfCCAs8IUmrhNs346pOvWRJ5p75OlrjCqROAXHkzI4D8RxbqHY7SR3UgYWPQUVKgL3b0GBFw9LG+OT94+EZEY74DT3aNO4gwtena3S0TpT0DiE2gEH74PkBtPxMcwkLnjIPLP4svNnbIG7LHQFVPi1cNC3i8QBhfEcFkoP3lP6EXz6dwibKpWj6KifQG42HmiLOnaAoTtSIHY9LTlMknOs8dIVYpzLtTrAfRoX94frX0lOuP51t1pkchOlmbgnlrfmJJKTeTbSAZj ptfs@dev2.vm.bytemark.co.uk" | tee /home/koha/.ssh/authorized_keys
chown -R "$dev_user":"$dev_user" /home/"$dev_user"

# Configure Dev Koha
su "$dev_user" << EOF
cd /home/"$dev_user"
git config --global user.name ""$author_name""
git config --global user.email ""$author_email""
git config --global color.status auto
git config --global color.branch auto
git config --global color.diff   auto
git config --global diff.tool vimdiff
git config --global difftool.prompt false
git config --global alias.d difftool
git config --global core.whitespace trailing-space,space-before-tab
git config --global apply.whitespace fix
git clone git://github.com/PTFS-Europe/koha.git kohaclone
cd kohaclone
git remote add community git://git.koha-community.org/koha.git
git remote rename origin ptfs
git fetch --all
git checkout -b master --track community/master
git branch -D master.ptfs
cd
git clone https://github.com/mkfifo/koha-gitify.git .gitify
cd .gitify
sudo ./koha-gitify "$instance_name" /home/"$dev_user"/kohaclone
EOF

service apache2 restart

# Configure git-bz
su "$dev_user" << EOF
cd /home/"$dev_user"
git clone git://git.koha-community.org/git-bz.git .gitbz
cd .gitbz
git fetch origin
git checkout -b fishsoup origin/fishsoup
sudo ln -s /home/"$dev_user"/.gitbz/git-bz /usr/local/bin/git-bz
EOF

su "$dev_user" << EOF
cd /home/"$dev_user"/kohaclone
git config bz.default-tracker bugs.koha-community.org
git config --global bz-tracker.bugs.koha-community.org.path /bugzilla3
git config bz.default-product Koha
git config --global bz-tracker.bugs.koha-community.org.bz-user "$author_email"
git config --global bz-tracker.bugs.koha-community.org.bz-password "$bugz_pass"
EOF

# Configure koha-qa
yes | aptitude install libfile-chdir-perl libgit-repository-perl liblist-compare-perl libmoo-perl libperl-critic-perl libsmart-comments-perl dh-make-perl
cd /root
mkdir dhmake
cd dhmake
cpan2deb Test::Perl::Critic::Progressive
dpkg -i *.deb
cd

su "$dev_user" << EOF
cd /home/"$dev_user"
git clone git://git.koha-community.org/qa-test-tools.git .kohaqa
ln -s ~/.kohaqa/perlcriticrc ~/.perlcriticrc
EOF

cat >> /home/"$dev_user"/.bashrc <<EOL

# User specific aliases and functions
export KOHA_CONF=/etc/koha/sites/${instance_name}/koha-conf.xml
export PERL5LIB="\${PERL5LIB}":/home/${dev_user}/kohaclone:/home/${dev_user}/kohaclone/C4/SIP:/home/${dev_user}/.kohaqa
alias qa="/home/${dev_user}/.kohaqa/koha-qa.pl"
EOL

# Install Profiler
yes | aptitude install libdevel-nytprof-perl

# Install Debugger
yes | aptitude install curl
su "$dev_user" << EOF
mkdir -p ~/.vim/autoload ~/.vim/bundle && curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

cat >> ~/.vimrc <<EOL
execute pathogen#infect()
syntax on
filetype plugin indent on
EOL

cd ~/.vim/bundle && git clone git://github.com/tpope/vim-sensible.git && git clone https://github.com/joonty/vdebug.git

cat >> ~/.vimrc <<EOL
call pathogen#helptags()
EOL

cd
wget http://downloads.activestate.com/Komodo/releases/archive/4.x/4.4.1/remotedebugging/Komodo-PerlRemoteDebugging-4.4.1-20896-linux-x86.tar.gz
tar xzf Komodo-PerlRemoteDebugging-4.4.1-20896-linux-x86.tar.gz
mv Komodo-PerlRemoteDebugging-4.4.1-20896-linux-x86 ~/.komodo-debug
rm -rfv Komodo-PerlRemoteDebugging-4.4.1-20896-linux-x86

EOF
