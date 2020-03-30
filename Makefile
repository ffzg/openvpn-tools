all:
	@echo "make install"


install:
	sudo ln -s /srv/openvpn-tools/openvpn2influx.service /etc/systemd/system/
	sudo systemctl enable openvpn2influx.service
	sudo systemctl start openvpn2influx.service

