#!/bin/sh
#cat <<EOF | sudo tee /usr/local/sbin/restart-vm-tools
#!/bin/sh

systemctl stop run-vmblock\\\\x2dfuse.mount
killall -q -w vmtoolsd
systemctl start run-vmblock\\\\x2dfuse.mount
systemctl enable run-vmblock\\\\x2dfuse.mount
vmware-user-suid-wrapper vmtoolsd -n vmusr 2>/dev/null
vmtoolsd -b /var/run/vmroot 2>/dev/null
EOF

chmod +x /usr/local/sbin/restart-vm-tools
#restart-vm-tools
