#!/bin/bash


cd /opt/bloodhound
sudo docker-compose up -d
sudo docker-compose logs >> bloodhound.log
exit 0