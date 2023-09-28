#!/bin/bash


cd /opt/mythic/
sudo /opt/mythic/mythic-cli install github https://github.com/MythicC2Profiles/http
sudo /opt/mythic/mythic-cli install github https://github.com/MythicC2Profiles/tcp
sudo /opt/mythic/mythic-cli install github https://github.com/MythicC2Profiles/smb
sudo /opt/mythic/mythic-cli install github https://github.com/MythicAgents/Apollo.git
sudo /opt/mythic/mythic-cli install github https://github.com/MythicAgents/merlin
sudo /opt/mythic/mythic-cli install github https://github.com/MythicAgents/medusa
sudo /opt/mythic/mythic-cli install github https://github.com/MythicAgents/Athena
sudo /opt/mythic/mythic-cli install github https://github.com/MythicAgents/thanatos
sudo sed -i 's/REBUILD_ON_START="true"/REBUILD_ON_START="false"/g' /opt/mythic/.env
sudo /opt/mythic/mythic-cli start
sudo /opt/mythic/mythic-cli stop
