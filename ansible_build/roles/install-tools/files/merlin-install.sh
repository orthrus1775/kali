#!/bin/bash
sudo mkdir /opt/merlin;cd /opt/merlin
sudo wget https://github.com/Ne0nd0g/merlin/releases/latest/download/merlinServer-Linux-x64.7z
sudo wget https://github.com/Ne0nd0g/merlin/releases/download/v1.5.1/merlinAgent-Windows-x64.7z
sudo wget https://github.com/Ne0nd0g/merlin/releases/download/v1.5.1/merlinAgent-Linux-x64.7z
sudo wget https://github.com/Ne0nd0g/merlin/releases/download/v1.5.1/merlinAgent-Darwin-x64.7z
sudo 7z x -pmerlin merlinServer-Linux-x64.7z
echo "# MERLIN  " > README.md
echo "Read how to use pre-compiled agents" >> README.md
echo "https://merlin-c2.readthedocs.io/en/latest/#" >> README.md