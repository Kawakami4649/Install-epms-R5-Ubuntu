sudo systemctl stop epstrd
sudo systemctl stop epstdd
sudo systemctl stop epstpop3d
sudo systemctl stop epsyimap4d
sudo rm -fr /usr/local/mta/
sudo rm -fr /var/www/html/epms/
sudo rm -fr /var/spool/epms/
cd Install-epms-R5-Ubuntu/
./install.sh
cd ..
sudo systemctl start epstrd
sudo systemctl start epstdd
sudo systemctl start epstpop3d
sudo systemctl start epstimap4d

