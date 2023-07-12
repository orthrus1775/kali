#!/bin/bash


check_perms(){
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi
}

# update sudoers.d  
update_sudod(){
sudo echo "$(logname) ALL=(ALL) NOPASSWD:ALL" >> /tmp/buildprep
sudo visudo -cf /tmp/buildprep > /dev/null
if [ $? -eq 0 ]; then
  # Replace the sudoers file with the new only if syntax is correct.
  sudo cp /tmp/buildprep /etc/sudoers.d/
  echo "[+] Updated sudoers.d to prevent sudo timeout"
else
  echo "[!] Could not modify /etc/sudoers.d file. Please do this manually."
fi


}

prep_env(){
sudo pip3 install ansible > /dev/null
if [ $? -eq 0 ]; then
  sudo ansible-galaxy install -r $(pwd)/ansible_build/requirements.yml > /dev/null
  if [ $? -eq 0 ]; then
    echo "[+] Successfully installed ansible and additional requirments"
  else
    echo "[!] Could not install requirments with ansible-galaxy. Please do this manually" 
  fi
else
  echo "[!] Could not install ansible. Please do this manually."
fi
}

run_playbook(){
echo "[*] Setup complete "
echo "[*] Run sudo whoami "
echo "[*] Run ansible-playbook main.yml as $(logname) with out sudo "

}

check_perms
update_sudod
prep_env
run_playbook
