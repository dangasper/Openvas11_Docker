#!/bin/bash

apt-get update

apt-get install -yq --no-install-recommends \
apt-utils \
bison \
build-essential \
ca-certificates \
clang-format \
cmake \
curl \
doxygen \
gcc \
gcc-mingw-w64 \
geoip-database \
git \
gnutls-bin \
graphviz \
heimdal-dev \
ike-scan \
libgcrypt20-dev \
libglib2.0-dev \
libgnutls28-dev \
libgpgme11-dev \
libhiredis-dev \
libical2-dev \
libksba-dev \
libldap2-dev \
libradcli-dev \
libradcli4 \
libmicrohttpd-dev \
libnet-snmp-perl \
libpcap-dev \
libpopt-dev \
libsnmp-dev \
libssh-gcrypt-dev \
libxml2-dev \
net-tools \
nikto \
nmap \
nsis \
nsis-common \
openssh-client \
perl-base \
pkg-config \
postgresql \
postgresql-contrib \
postgresql-server-dev-all \
python3-defusedxml \
python3-dialog \
python3-lxml \
python3-paramiko \
python3-pip \
python3-polib \
python3-psutil \
python3-setuptools \
rake \
redis-server \
redis-tools \
rsync \
sendmail \
smbclient \
socat \
sshpass \
texlive-fonts-recommended \
texlive-latex-extra \
uuid-dev \
wapiti \
wget \
whiptail \
xml-twig-tools \
xmltoman \
xsltproc

curl -sL https://deb.nodesource.com/setup_10.x | bash -
apt-get install nodejs -yq --no-install-recommends

curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
apt-get update
apt-get install yarn -yq --no-install-recommends

rm -rf /var/lib/apt/lists/*
