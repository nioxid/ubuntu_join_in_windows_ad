#!/bin/bash
# Create error counter
ERROR=0
NOERROR=0
# Domain controller hostname
DC="my_domain_controller"
#Domain name
DOMAIN="my_domain"
#Login domain administrator
DOMAIN_ADMIN="domain_admin"
echo "====================="
echo "Configure DNS Resolved"
echo "====================="
echo ""
tee -a /etc/systemd/resolved.conf <<EOF
DNS=10.0.0.1 10.0.0.2
Domains=my_domain
LLMNR=no
DNSSEC=no
EOF
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
systemctl restart systemd-resolved.service
echo ""
echo ""
echo "====================="
echo "Add libreoffice repo"
echo "====================="
cat <<EOF >/etc/apt/sources.list.d/libreoffice-ubuntu-ppa-focal.list
deb https://ppa.launchpadcontent.net/libreoffice/ppa/ubuntu focal main
EOF
echo ""
echo "====================="
echo "Add libreoffice PPA key"
echo "====================="
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 36E81C9267FD1383FCC4490983FBA1751378B444
echo ""
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
echo "====================="
echo "apt update"
echo "====================="
echo ""
apt update
echo ""
echo ""
echo "====================="
echo "Enter computer hostname."
echo "====================="
echo ""

read HOSTNAME

if [ "$HOSTNAME" = "" ]; then

echo "hostname do not be empty!"
read -sn1 -p "press any key to exit."; echo
    exit
fi

echo ""
echo "====================="
echo "You enter hostname:"
echo $HOSTNAME
echo ""

read -sn1 -p "If it correct, press any key... or Ctrl+C for cancel."; echo

hostnamectl set-hostname $HOSTNAME

echo ""
echo "====================="
echo "Install packages"
echo "====================="
echo ""
apt install -y sssd heimdal-clients msktutil realmd packagekit adcli sssd-tools libnss-sss libpam-sss samba-common-bin oddjob oddjob-mkhomedir openssh-server x11vnc libpam-mount cifs-utils ubuntu-restricted-extras libenchant1c2a cabextract evolution evolution-ews libodbc1
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
echo ""
echo ""
echo "====================="
echo "Check DC controller resolve"
echo "====================="
echo ""
nslookup $DC
ping -c 3 $DC
echo ""
sleep 2
echo ""
echo "====================="
echo "Search DC controllers on-line"
echo "====================="
echo ""
realm discover $DOMAIN
echo ""
echo ""

adcli info $DOMAIN

echo ""
echo ""
echo "====================="
echo "Join in domain"
echo "====================="
echo ""
realm join -U $DOMAIN_ADMIN $DOMAIN
echo ""
echo ""
echo "====================="
echo "Change parameter use_fully_qualified_names for the ability to enter a user name without specifying a domain"
echo "====================="
echo ""
cp /etc/sssd/sssd.conf /etc/sssd/sssd.conf_orig
sed -i 's/.*use_fully_qualified_names.*/use_fully_qualified_names = False/' /etc/sssd/sssd.conf
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
cat /etc/sssd/sssd.conf | grep use_fully_qualified_names
sleep 2
echo ""
echo "====================="
echo "Setting user home directory path"
echo "====================="
echo ""
sed -i 's/.*fallback_homedir.*/fallback_homedir = \/home\/%u/' /etc/sssd/sssd.conf
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
cat /etc/sssd/sssd.conf | grep fallback_homedir
echo "ad_gpo_access_control = disabled" >> /etc/sssd/sssd.conf
sleep 2
echo ""
echo "====================="
echo "Enable and restarting sssd service"
echo "====================="
echo ""
systemctl enable sssd.service
systemctl restart sssd.service
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi

echo ""
echo ""
echo "====================="
echo "Starting pam-auth-update and check box create user home directory"
echo "====================="
echo ""
pam-auth-update --enable mkhomedir
echo ""
echo "====================="
echo "Getting information about the domain"
echo "====================="
echo ""
realm list
echo ""
echo ""

adcli info $DOMAIN

echo ""
sleep 2
echo ""
echo "====================="
echo "Add workstationadmins in sudoers"
echo "====================="
echo ""
echo "%workstationadmins ALL=(ALL:ALL) ALL" >> /etc/sudoers
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
echo ""
echo "====================="
echo "Setting HASP for 1С"
echo "====================="
echo ""
mkdir -p /opt/1cv8/conf
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
cat  <<EOF > /opt/1cv8/conf/nethasp.ini
[NH_COMMON]
NH_TCPIP = Enabled
[NH_TCPIP]
NH_SERVER_ADDR = 10.0.0.1
EOF
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
echo ""
echo "====================="
echo "Add 1c conf file"
echo "====================="
echo ""
echo ""
cat  <<EOF > /opt/1cv8/conf/conf.ini
SystemLanguage=RU
ConfLocation=/opt/1cv8/conf/
EOF
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
echo ""
echo "====================="
echo "switch off wayland"
echo "====================="
echo ""
echo ""
sed -i 's/#WaylandEnable=false/WaylandEnable=false/g' /etc/gdm3/custom.conf
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
echo "====================="
echo "Change password quality"
echo "====================="
echo ""
sed -i 's/retry=3/retry=5 minlen=8 difok=4 lcredit=-2 ucredit=-2 dcredit=-1 ocredit=-1 maxrepeat=2 maxsequence=2 reject_username enforce_for_root/g' /etc/pam.d/common-password
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
sleep 2
echo ""
echo "====================="
echo "Activate updating user password in keyring"
echo "====================="
cat <<EOF >> /etc/pam.d/passwd
password optional pam_gnome_keyring.so
EOF
echo "====================="
echo "Mount free share"
echo "====================="
sed -i 's/<!-- Volume definitions -->/<!-- Volume definitions -->\n                <volume fstype="cifs" server="my_fileserver" path="my_share_path" mountpoint="~\/share_folder" options="user,owner,noexec,noserverino,iocharset=utf8,rw,vers=3.1.1" \/>/g' /etc/security/pam_mount.conf.xml
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
sleep 2
echo ""
echo ""
echo "====================="
echo "Disable keyring ssh autostart"
echo "====================="
echo ""
cat <<EOF >> /etc/xdg/autostart/gnome-keyring-ssh.desktop
X-GNOME-Autostart-enabled=false
EOF
echo ""
echo "====================="
echo "Change default blank screen timeout and organize favorites apps"
echo "====================="
echo ""
echo ""
mkdir -p /etc/dconf/db/local.d/
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
mkdir -p /etc/dconf/db/gdm.d/
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
#Disable the user list
cat <<EOF > /etc/dconf/profile/gdm
user-db:user
system-db:gdm
file-db:/usr/share/gdm/greeter-dconf-defaults
EOF
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
cat <<EOF > /etc/dconf/db/gdm.d/00-login-screen
[org/gnome/login-screen]
# Do not show the user list
disable-user-list=true
EOF
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
#Display a text banner on the login screen
cat <<EOF > /etc/dconf/db/gdm.d/01-banner-message
[org/gnome/login-screen]
banner-message-enable=true
banner-message-text="Требования к паролям:\n1) Использование только английского алфавита.\n2) Наличие 2х букв верхнего и нижнего регистра (большие и маленькие буквы)\n3) Наличие минимум одной цифры (1234567890)\n4) Наличие минимум одного спец. знака\n(!\";%:?\*()_+=-\~\/\\\<\>,.[]{})\n5)Длина не менее девяти символов\n6)При смене пароля новый не должен совпадать с 5-ю предыдущими более чем на 70%"
EOF
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
cat  <<EOF > /etc/dconf/profile/user
user-db:user
system-db:local
EOF
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
cat  <<EOF > /etc/dconf/db/local.d/00-screensaver
[org/gnome/desktop/session]
# Number of seconds of inactivity before the screen goes blank
# Set to 0 seconds if you want to deactivate the screensaver.
idle-delay=uint32 1800
# Specify the dconf path
[org/gnome/desktop/screensaver]
# Number of seconds after the screen is blank before locking the screen
lock-delay=uint32 0
EOF
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
cat  <<EOF > /etc/dconf/db/local.d/00-favorite-apps
# Snippet sets default favorites for all users
[org/gnome/shell]
favorite-apps = ['firefox.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Evolution.desktop', '1cv8c-8.3.18-1483.desktop', '1cv8s-8.3.20-1674.desktop', 'org.remmina.Remmina.desktop']
# Extensions minimize on click
[org/gnome/shell/extensions/dash-to-dock]
click-action = "minimize"
EOF
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
cat  <<EOF > /etc/dconf/db/local.d/00-nautilus
# prevent showing thumbnails
[org/gnome/nautilus/preferences]
show-image-thumbnails = "never"
show-directory-item-counts = "never"
default-folder-viewer = "list-view"
EOF
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
dconf update
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
sleep 2
echo "====================="
echo "Create remmina_create service script"
echo "====================="
cat <<'EOT' > /etc/systemd/user/default.target.wants/remmina_create.sh
#!/bin/bash
# Checking the presence of a folder
REMDIR=~/.local/share/remmina
if [ -e $REMDIR ]
then
echo "Dir already exists."
else
mkdir ~/.local/share/remmina
fi

REM=group_rdp_terminal_terminal

# Search config file
connection=~/.local/share/remmina/group_rdp_terminal_terminal.remmina

# if it not find, create from a template
if [ -e $connection ]
then
echo connection create
else
cat  <<EOF > ~/.local/share/remmina/group_rdp_terminal_terminal.remmina
[remmina]
password=
gateway_username=
notes_text=
vc=
window_height=564
scale=2
preferipv6=0
ssh_tunnel_loopback=0
serialname=
printer_overrides=
name=terminal
console=0
colordepth=64
security=
precommand=
disable_fastpath=0
left-handed=0
postcommand=
multitransport=0
group=
server=terminal
ssh_tunnel_certfile=
glyph-cache=0
ssh_tunnel_enabled=0
disableclipboard=0
audio-output=
parallelpath=
monitorids=
cert_ignore=0
gateway_server=
serialpermissive=0
protocol=RDP
ssh_tunnel_password=
old-license=0
resolution_mode=2
loadbalanceinfo=
disableautoreconnect=0
clientbuild=
clientname=
resolution_width=0
drive=
relax-order-checks=0
username=
base-cred-for-gw=0
gateway_domain=
network=lan
rdp2tcp=
gateway_password=
rdp_reconnect_attempts=
domain=ea
serialdriver=
smartcardname=
serialpath=
exec=
multimon=0
enable-autostart=0
usb=
shareprinter=0
ssh_tunnel_passphrase=
disablepasswordstoring=1
quality=2
span=0
shareparallel=0
parallelname=
viewmode=4
ssh_tunnel_auth=0
execpath=
ssh_tunnel_username=
sharesmartcard=0
shareserial=0
resolution_height=0
sharefolder=
useproxyenv=0
timeout=
freerdp_log_filters=
microphone=
dvc=
ssh_tunnel_privatekey=
gwtransp=http
ssh_tunnel_server=
ignore-tls-errors=1
window_maximize=1
keyboard_grab=1
disable-smooth-scrolling=0
gateway_usage=0
window_width=717
freerdp_log_level=INFO
sound=off
EOF
fi

echo $USER | remmina --update-profile ~/.local/share/remmina/group_rdp_terminal_terminal.remmina --set-option username

# Enable fontsmoothing
sed -i 's/rdp_quality_0=.*/rdp_quality_0=CF/g' ~/.config/remmina/remmina.pref
sed -i 's/rdp_quality_1=.*/rdp_quality_1=CF/g' ~/.config/remmina/remmina.pref
sed -i 's/rdp_quality_2=.*/rdp_quality_2=CF/g' ~/.config/remmina/remmina.pref
sed -i 's/rdp_quality_9=.*/rdp_quality_9=CF/g' ~/.config/remmina/remmina.pref

# Create firefox proxy setting file

# Search config file
proffire=(~/.mozilla/firefox/*.default-release/user.js)
prof=(~/.mozilla/firefox/*.default-release)

# if it not find, create from a template
if [ -e ${proffire[@]}  ]
then
echo proffire create
else
cat  <<EOF > ${prof[@]}/user.js
user_pref("network.dns.disablePrefetch", true);
user_pref("network.http.speculative-parallel-limit", 0);
user_pref("network.predictor.enabled", false);
user_pref("network.prefetch-next", false);
user_pref("network.proxy.backup.ssl", "");
user_pref("network.proxy.backup.ssl_port", 0);
user_pref("network.proxy.http", "proxy_server");
user_pref("network.proxy.http_port", 3128);
user_pref("network.proxy.no_proxies_on", "localhost,127.0.0.0/8,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12");
user_pref("network.proxy.share_proxy_settings", true);
user_pref("network.proxy.ssl", "proxy_server");
user_pref("network.proxy.ssl_port", 3128);
user_pref("network.proxy.type", 1);
user_pref("network.trr.mode", 5);
user_pref("general.autoScroll", true);
EOF
fi

# Create Mount free share
if [ -e ~/share_folder ]
then echo free directoty allready created
else
mkdir ~/share_folder
fi

# Create 1c config file dir
if [ -e ~/.1C/1cestart ]
then echo directoty allready created
else
mkdir -p ~/.1C/1cestart
fi
# Create 1c config file
if [ -e ~/.1C/1cestart/1cestart.cfg ]
then echo 1cestart.cfg allready created
else
cat << EOF> ~/.1C/1cestart/1cestart.cfg
CommonInfoBases=/home/$USER/share_folder/1cestart/1.v8i
CommonInfoBases=/home/$USER/share_folder/1cestart/2.v8i
CommonInfoBases=/home/$USER/share_folder/1cestart/3.v8i
CommonInfoBases=/home/$USER/share_folder/1cestart/4.v8i
CommonInfoBases=/home/$USER/share_folder/1cestart/5.v8i
CommonInfoBases=/home/$USER/share_folder/1cestart/6.v8i
UseHWLicenses=1
AppAutoInstallLastVersion=1
EOF
fi

# ADD hostname, user and data
echo HOSTNAME:$HOSTNAME USER:$USER $(date "+DATE: %D%nTIME: %T")  >> ~/share_folder/users/$USER.txt
EOT
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
chmod +x /etc/systemd/user/default.target.wants/remmina_create.sh
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
echo ""
echo ""
echo "====================="
echo "Create remmina_user service"
echo "====================="
echo ""
cat  <<EOF > /usr/lib/systemd/user/remminauser.service
[Unit]
Description=Create remmina config at startup.
After=multi-user.target
[Service]
Type=simple
ExecStart=/bin/bash /etc/systemd/user/default.target.wants/remmina_create.sh
[Install]
WantedBy=multi-user.target
EOF
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
ln -s /usr/lib/systemd/user/remminauser.service /etc/systemd/user/default.target.wants/remminauser.service
if [[ "x$?" == "x0" ]]; then ((NOERROR=NOERROR+1)) && echo "no errors"; else ((ERROR=ERROR+1)) && echo "you have some errors"; fi
echo ""
echo ""
echo "====================="
echo "View error counter"
echo "====================="
echo Error: $ERROR
sleep 3
echo "====================="
echo "Enable service"
echo "====================="
echo ""
su my_user
systemctl --user daemon-reload
systemctl --user enable remminauser.service
systemctl --user start remminauser.service
read -sn1 -p "if this script runs with no errors reboot and login like domain user,  else fix your errors and run this script again."; echo