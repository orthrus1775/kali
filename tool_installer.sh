#!/bin/bash

# Tools and things I run on Kali


mkdir /root/tools
cd ~/tools
gem install evil-winrm
apt-get install terminator -y
apt-get install ftp -y
apt-get install python-pip -y
apt-get install python3-pip -y
apt-get install libncurses5-dev -y
apt-get install bloodhound -yr
apt-get install awscl -y
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
pip install boto3
pip install pyasn1
pip install pycryptodomex
pip install pyOpenSSL
pip install ldapdomaindump
pip install flask
pip install python3-ldap
pip install pyReadline
pip install dnspython
pip install argparse

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
pip install -r requirements.txt
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
python3 -m pip install -r requirements.txt
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

#Install slurp
#git clone https://github.com/hehnope/slurp
#cd slurp
#go build
#cd ~/tools

#Install One-Lin3r
#git clone https://github.com/D4Vinci/One-Lin3r.git
#cd One-Lin3r
#pip install ./One-Lin3r
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

#Install Windapsearch
git clone https://github.com/ropnop/windapsearch.git
apt-get install libsasl2-dev python-dev libldap2-dev libssl-dev
pip install python-ldap
ln -sf /root/tools/windapsearch/windapsearch.py /usr/bin/windapsearch
cd ~tools

#Install Nishang
git clone https://github.com/samratashok/nishang.git

#Install Powersploit
git clone https://github.com/PowerShellMafia/PowerSploit

#Install impacket
git clone https://github.com/SecureAuthCorp/impacket.git
cd impacket
#adding kerbrute
git clone https://github.com/TarlogicSecurity/kerbrute
cd kerbrute
cp kerbrute.py ../kerbrute.py
cd ..
chmod 777 kerbrute.py
rm -r kerbrute
pip install .
cd ~/tools

#Install Evilginx
#apt-get install git make
#go get -u github.com/kgretzky/evilginx2
#cd $GOPATH/src/github.com/kgretzky/evilginx2
#make
#make install
wget https://github.com/kgretzky/evilginx2/releases/download/2.3.0/evilginx_linux_x86_2.3.0.zip
unzip evilginx_linux_x86_2.3.0.zip -d evilginx
cd evilginx
chmod 700 install.sh
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
git clone https://github.com/an0nlk/Nosql-MongoDB-injection-username-password-enumeration.git

#Install Legion
cd ~tools
git clone https://github.com/carlospolop/legion.git /root/tools/legion
cd legion/git
cd ./install.sh
ln -s /root/tools/legion/legion.py /usr/bin/legion

#Install veil
/usr/share/veil/config/setup.sh --force --silent

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
reboot

