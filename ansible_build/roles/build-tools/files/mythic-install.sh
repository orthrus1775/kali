#!/bin/bash

export PATH=/opt/mythic/:$PATH
sudo apt install docker-compose -y
sudo mythic-cli install github https://github.com/MythicAgents/apollo
sudo mythic-cli install github https://github.com/MythicC2Profiles/http
sudo mythic-cli install github https://github.com/MythicC2Profiles/tcp
sudo mythic-cli install github https://github.com/MythicC2Profiles/smb
mythic-cli start
