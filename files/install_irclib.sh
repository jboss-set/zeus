#!/bin/bash

echo -e "Downloading irclib 0.4.8"
[ ! -f version_0_4_8.zip ] && wget https://github.com/jaraco/irc/archive/version_0_4_8.zip

unzip version_0_4_8.zip
cd irc-version_0_4_8

echo -e "Make the files"
make

echo -e "Install python module"
python setup.py install

echo -e "Remove the installation files"
cd ..
rm -rf irc-version_0_4_8
rm -rf version_0_4_8.zip

