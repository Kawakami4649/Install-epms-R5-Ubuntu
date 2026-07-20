sudo tar xfvz epms-R5-Ubuntu.tar.gz -C /
sudo chown www-data:www-data /var/spool/epms/db/chat.local.idx
sudo chown root:root /etc
sudo chown root:root /etc/systemd/
sudo chown root:root /etc/systemd/system/
sudo chown root:root /etc/systemd/system/epstimap4d.service
sudo chown root:root /etc/systemd/system/epstpop3d.service
sudo chown root:root /etc/systemd/system/epstdd.service
sudo chown root:root /etc/systemd/system/epstrd.service
sudo systemctl enable epstrd.service
sudo systemctl enable epstdd.service
sudo systemctl enable epstpop3d.service
sudo systemctl enable epstimap4d.service
sudo rm /var/spool/epms/reg/epost/ims/EPST5POP3S/AcceptlogEnabled.1
sudo rm /var/spool/epms/reg/epost/ims/EPST5RS/Parameters/MailInlogEnabled.1
sudo rm /var/spool/epms/reg/epost/ims/EPST5RS/3rdViruslog.1
sudo rm /var/spool/epms/reg/epost/ims/EPST5RS/AcceptlogEnabled.1
sudo rm /var/spool/epms/reg/epost/ims/EPST5DS/MailFaillogEnabled.1
sudo rm /var/spool/epms/reg/epost/ims/EPST5DS/Parameters/MailSendLocallogEnabled.1
sudo rm /var/spool/epms/reg/epost/ims/EPST5DS/Parameters/MailOutlogEnabled.1
sudo rm /var/spool/epms/reg/epost/ims/EPST5DS/Sender2logEnabled.1
sudo rm /var/spool/epms/reg/epost/ims/EPST5IMAP4S/AcceptlogEnabled.1
sudo tar xfvz epstman_cgi.tar.gz -C /
sudo tar xfvz dmarc-lib.tar.gz -C /
sudo chown -fR root:root /var/www/html/epms/
sudo chown -fR root:www-data /var/spool/epms/
sudo tar xfvz SysPassword.tar.gz -C /
sudo tar xfvz add_ssl_reg.tar.gz -C /
sudo cp create_cert.sh /usr/local/bin/
sudo cp renew_cert.sh /usr/local/bin/
sudo cp add_cron.sh /usr/local/bin/
sudo cp remove_cron.sh /usr/local/bin/
sudo cp reset_epms.sh /usr/local/bin/
sudo cp backup_epms.sh /usr/local/bin/
sudo cp restore_epms.sh /usr/local/bin/
# sudo cp format_media.sh /usr/local/bin/
sudo /usr/local/bin/create_cert.sh chat.local
sudo /usr/local/bin/add_cron.sh chat.local
sudo tar xfvz epms-R5-Ubuntu-bin-diff-20260611.tar.gz -C /usr/local/mta/bin/
sudo tar xfvz epms-R5-Ubuntu-html-diff-20260429.tar.gz -C /var/www/html/

