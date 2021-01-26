#!/bin/bash

# Tools and things I run on your pentest system



printf "\e[1;33m
███████╗ ██████╗ █████╗ ██████╗ ██████╗  ██████╗ ██████╗ ██████╗
██╔════╝██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔═══██╗██╔══██╗██╔══██╗
███████╗██║     ███████║██████╔╝██████╔╝██║   ██║██████╔╝██║  ██║
╚════██║██║     ██╔══██║██╔══██╗██╔══██╗██║   ██║██╔══██╗██║  ██║
███████║╚██████╗██║  ██║██████╔╝██████╔╝╚██████╔╝██║  ██║██████╔╝
╚══════╝ ╚═════╝╚═╝  ╚═╝╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═════╝
\e[0m"


mkdir /root/tools
sed -i -- 's/#\s\?deb-src/deb-src/g' /etc/apt/sources.list
apt-get update -y && apt-get upgrade -y
cd ~/tools
gem install evil-winrm
apt-get install ftp -y
apt-get install python-pip -y
apt-get install python3-pip -y
apt-get install python-venv
apt-get install libncurses5-dev -y
apt-get install bloodhound -y
apt-get install awscli -y
apt-get install powershell -y
apt-get install xrdp -y
apt-get install veil -y
apt-get install gobuster -y
apt-get install oscanner -y
apt-get install smtp-user-enum -y
apt-get install tnscmd10g -y
apt-get install wkhtmltopdf -y
apt-get install sipvicious -y
apt-get install seclists -y
apt-get install golang-go -y
apt-get install shellter -y
apt-get install libssl-dev swig python3-dev gcc -y
searchsploit -u
pip3 install M2Crypto
pip3 install pipx
pipx ensurepath
pipx completions
pip3 install pyasn1
pip3 install pycryptodomex
pip3 install pyOpenSSL
pip3 install python3-ldap
pip3 install pyReadline
pip3 install dnspython
pip3 install argparse
pip3 install urllib3==1.22
pip3 install requests==2.18.4
pip3 install setuptools
pip3 install iptools
pip3 install pydispatcher
pip3 install macholib
pip3 install pyOpenSSL==17.2.0
pip3 install pyinstaller
pip3 install zlib_wrapper
pip3 install netifaces
pip3 install jinja2
pip3 install cryptography
pip3 install pyminifier==2.1
pip3 install xlutils
pip3 install pycrypto
pipx install boto3 --include-deps
pipx install ldapdomaindump
pipx install flask
pipx install dropbox --include-deps
pipx install one-lin3r 

#Install pyenv
git clone https://github.com/pyenv/pyenv.git ~/.pyenv
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.zshrc

#configure pipx
pipx ensurepath
echo 'eval "$(register-python-argcomplete pipx)"' >> ~/.zshrc

#Install WinboxExploit
git clone https://github.com/BigNerd95/WinboxExploit
cd WinboxExploit
chmod +x *.py
ln -sf /root/tools/WinboxExploit/WinboxExploit.py /usr/local/bin/WinboxExploit
ln -sf /root/tools/WinboxExploit/MACServerExploit.py /usr/local/bin/MACServerExploit
ln -sf /root/tools/WinboxExploit/MACServerDiscover.py /usr/local/bin/MACServerDiscover
ln -sf /root/tools/WinboxExploit/extract_user.py /usr/local/bin/extract_user

#Install pwnedOrNot
git clone https://github.com/thewhiteh4t/pwnedOrNot
ln -sf /root/tools/pwnedOrNot/pwnedornot.py /usr/bin/pwnedornot

#Install Sublist3r
git clone https://github.com/aboul3la/Sublist3r.git
cd Sublist3r
pip3 install -r requirements.txt
cd ~/tools
ln -sf /root/tools/Sublist3r/sublist3r.py /usr/local/bin/sublist3r


#Install AutoRecon
git clone https://github.com/Tib3rius/AutoRecon.git
cd AutoRecon
pip3 install -r requirements.txt
ln -sf /root/tools/AutoRecon/autorecon.py usr/local/bin/autorecon
cd ~/tools

#Install Routersploit
git clone https://www.github.com/threat9/routersploit
cd routersploit
python3 -m pip3 install -r requirements.txt
cd ~/tools
ln -sf /root/tools/routersploit/rsf.py /usr/bin/routersploit
ln -sf /root/tools/routersploit/rsf.py /usr/bin/rsfconsole
ln -sf /root/tools/routersploit/rsf.py /usr/bin/rsf

#Install go
#mkdir golang
#cd golang
#wget https://dl.google.com/go/go1.13.5.linux-amd64.tar.gz
#tar -xvf go1.13.5.linux-amd64.tar.gz
#export GOROOT=/root/tools/golang/go
#export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
#source ~/.profile
#cd ~/tools

#Install legion
git clone https://github.com/carlospolop/legion.git
cd legion/git
./install.sh
ln -sf /root/tools/legion/legion.py /usr/bin/legion
cd ~/tools

#Install slurp
#git clone https://github.com/hehnope/slurp
#cd slurp
#go build
#cd ~/tools

#Install Powershell Empire
git clone https://github.com/EmpireProject/Empire.git
cd Empire
chmod +x setup/install.sh
./setup/install.sh
cd ~/tools
ln -sf /root/tools/Empire/empire /usr/bin/empire

#Install JohnTheRipper
git clone https://github.com/magnumripper/JohnTheRipper.git
cd ~/tools

#Install Windapsearch
git clone https://github.com/ropnop/windapsearch.git
apt-get install libsasl2-dev python-dev libldap2-dev libssl-dev -y
pip3 install python-ldap
ln -sf /root/tools/windapsearch/windapsearch.py /usr/bin/windapsearch
cd ~tools

#Install Nishang
git clone https://github.com/samratashok/nishang.git
cd ~/tools

#Install Powersploit
git clone https://github.com/PowerShellMafia/PowerSploit
cd ~/tools

#Install impacket
git clone https://github.com/SecureAuthCorp/impacket.git
cd impacket
pip3 install -r requirments.txt
python3 setup.py install
cd ~/tools

#adding kerbrute
git clone https://github.com/TarlogicSecurity/kerbrute
cd kerbrute
sed -i '1s/^/#!\/usr\/bin\/env python3 \n/' kerbrute.py
chmod +x kerbrute.py
ln -sf /root/tools/kerbrute/kerbrute.py /usr/bin/kerbrute
cd ~/tools

#Install Evilginx
wget https://github.com/kgretzky/evilginx2/releases/download/2.3.0/evilginx_linux_x86_2.3.0.zip
unzip evilginx_linux_x86_2.3.0.zip -d evilginx
cd evilginx
chmod +x install.sh
./install.sh
cd ~/tools

#Install fuff
git clone https://github.com/ffuf/ffuf.git
cd ffuf
wget https://github.com/ffuf/ffuf/releases/download/v1.0.2/ffuf_1.0.2_linux_amd64.tar.gz
tar -xzvf ffuf_1.0.2_linux_amd64.tar.gz
cd ~/tools
ln -sf /root/tools/ffuf/ffuf /usr/bin/ffuf
cd ~/tools

#Install
git clone https://github.com/an0nlk/Nosql-MongoDB-injection-username-password-enumeration.git ~/tools/nosql-mongo-inject

#Install Legion
#cd ~tools
#git clone https://github.com/carlospolop/legion.git /root/tools/legion
#cd legion/git
#cd ./install.sh
#ln -s /root/tools/legion/legion.py /usr/bin/legion

#Install Active Directory Integrated DNS dump tool
git clone https://github.com/dirkjanm/adidnsdump 
cd adidnsdump
pip install .
cd ~/tools

#Install SilentTrinity
git clone https://github.com/byt3bl33d3r/SILENTTRINITY
cd SILENTTRINITY
pip3 install -r requirments.txt
pip3 install --user pipenv && pipenv install && pipenv shell
python3 st.py &

#Install Docker
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
echo 'deb [arch=amd64] https://download.docker.com/linux/debian buster stable' | sudo tee /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get remove docker docker-engine docker.io -y
apt install docker-ce -y
systemctl start docker
systemctl enable docker
Docker run hello-world

#Install PEASS
git clone https://github.com/carlospolop/privilege-escalation-awesome-scripts-suite.git ~/tools/peapod
cd ~/tools

#Install pspy
#https://github.com/DominicBreuker/pspy/releases/download/v1.2.0/pspy32s
#https://github.com/DominicBreuker/pspy/releases/download/v1.2.0/pspy64s

#Install veil
/usr/share/veil/config/setup.sh --force --silent

one-lin3r &
evilginx &
sublist3r &
pwnedornot &
routersploit &
rsfconsole &
rsf &
windapsearch &
empire &
ffuf &
shellter &
apt-get update -y && apt-get upgrade -y

read -p "Press [ENTER] to finish"
reboot
