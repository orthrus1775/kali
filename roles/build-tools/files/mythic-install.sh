#!/bin/bash


cd /opt/mythic/
sudo ./install_docker_kali.sh
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicC2Profiles/http
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicC2Profiles/tcp
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicC2Profiles/smb
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicC2Profiles/httpx.git
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicAgents/Apollo
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicAgents/merlin
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicAgents/medusa
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicAgents/Athena
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicAgents/thanatos
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicAgents/arachne
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicAgents/bloodhound.git
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicAgents/ghostwriter
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicAgents/service_wrapper.git
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicAgents/scarecrow_wrapper
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicAgents/pickle_wrapper.git
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicAgents/Hannibal.git
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicAgents/Xenon.git
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicAgents/forge.git
sudo /opt/Mythic/mythic-cli install github https://github.com/Whispergate/Starburst.git
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicAgents/poseidon.git
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicC2Profiles/registry_browser
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicC2Profiles/ldap_browser
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicC2Profiles/basic_logger.git
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicC2Profiles/dns.git
sudo /opt/Mythic/mythic-cli install github https://github.com/galoryber/fawkes.git
sudo /opt/Mythic/mythic-cli install github https://github.com/Whispergate/Erebus
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicAgents/Woopsie.git
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicAgents/Poopsie.git
sudo /opt/Mythic/mythic-cli install github https://github.com/ZZ0R0/Proteus.git
sudo /opt/Mythic/mythic-cli install github https://github.com/Whispergate/Tyche.git
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicC2Profiles/dynamichttp.git
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicAgents/Kharon-Mtc.git
sudo /opt/Mythic/mythic-cli install github https://github.com/MythicC2Profiles/mqtt.git


sed -i 's/restart: always/restart: on-failure:10/g' docker-compose.yml
sudo sed -i 's/REBUILD_ON_START="true"/REBUILD_ON_START="false"/g' /opt/mythic/.env
sudo /opt/Mythic/mythic-cli stop
sleep 45
