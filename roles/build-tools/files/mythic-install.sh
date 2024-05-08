#!/bin/bash


cd /opt/mythic/
sudo /opt/mythic/mythic-cli install github https://github.com/MythicC2Profiles/http
sudo /opt/mythic/mythic-cli install github https://github.com/MythicC2Profiles/tcp
sudo /opt/mythic/mythic-cli install github https://github.com/MythicC2Profiles/smb
sudo /opt/mythic/mythic-cli install github https://github.com/MythicC2Profiles/httpx.git
sudo /opt/mythic/mythic-cli install github https://github.com/MythicAgents/Apollo
sudo /opt/mythic/mythic-cli install github https://github.com/MythicAgents/merlin
sudo /opt/mythic/mythic-cli install github https://github.com/MythicAgents/medusa
sudo /opt/mythic/mythic-cli install github https://github.com/MythicAgents/Athena
sudo /opt/mythic/mythic-cli install github https://github.com/MythicAgents/thanatos
sudo /opt/mythic/mythic-cli install github https://github.com/MythicAgents/arachne
sudo /opt/mythic/mythic-cli install github https://github.com/MythicAgents/sliver
sudo /opt/mythic/mythic-cli install github https://github.com/MythicAgents/bloodhound.git
#sudo /opt/mythic/mythic-cli install github https://github.com/MythicAgents/ghostwriter
#sudo /opt/mythic/mythic-cli install github https://github.com/MythicAgents/service_wrapper.git
#sudo /opt/mythic/mythic-cli install github https://github.com/MythicAgents/scarecrow_wrapper
#sudo /opt/mythic/mythic-cli install github https://github.com/MythicAgents/pickle_wrapper.git
sed -i 's/restart: always/restart: on-failure:10/g' docker-compose.yml
sudo sed -i 's/REBUILD_ON_START="true"/REBUILD_ON_START="false"/g' /opt/mythic/.env
sudo /opt/mythic/mythic-cli stop
sleep 45
