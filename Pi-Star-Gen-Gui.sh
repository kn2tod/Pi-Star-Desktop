#!/bin/bash
# Pi-Star on a Desktop!!  A "header" version of Pi-Star!
# Bookworm/Trixie gen to GUI:
#
# Assumptions:
#   user = pi-star/raspberry
#   Debian (linux) directory structures
#   system run in full-time write mode
#   hostapd/pistar-ap.service not started
#   connectivity to Internet handled by NetManager
#   configured to use Firefox for dashboard access
#   fully provisioned Pi: MMDVM Hat installed; monitor/display, keyboard, mouse
#
# preReq's:
#   iptables
#   dnsutils
#   xxd
#
# Nice to have:
#   batcat (bat)
#   prettyping
#   duf
#   pydf
#   speedtest
#   Shellcheck
#
# On a GUI version of Debian, install:
#   PHP/FPM
#   NGINX
#   Load Pi-Star+ from GIT:
#     dashboard
#     s-binaries
#     binaries
#     misc app files
#   configure NGINX
#   Set NGINX user/pswd
#   load initial host files (usr/local/etc)
#   load initial host files (etc)
#   Install WiringPi
#   ...
#   Fix up FSTAB
#   Install Shell-in-a-box
#   add group/user permissions
#   mod sudoers
#   fix cmdline.txt (net.ifnames)
#   install RSYSLOG
#   load/enable pistar tasks/timers
#
#  (sudo raspi-config nonint <command> <arguments>):
#  sudo raspi-config nonint do_hostname pi-star-???
#  sudo raspi-config nonint do_ssh 0
#  sudo raspi-config nonint do_spi 0
#  sudo raspi-config nonint do_i2c 0
#  sudo raspi-config nonint do_change_locale en_US.UTF-8 ?
#  sudo raspi-config nonint do_change_timezone America/New_York ?
#  sudo raspi-config nonint do_configure_keyboard us ?
#  sudo raspi-config nonint do_net_names 0
#  sudo raspi-config nonint do_serial ????
#
#  Testing:
#     trixie-armhf-full.img  # 32-bit
#     https://downloads.raspberrypi.com/raspios_full_armhf/images/raspios_full_armhf-2025-12-04/
#              2025-12-04-raspios-trixie-armhf-full.img.xz
#     Pi4b's and Pi5's
#
#  Build procedure:
#     build/configure Trixie Full system
#     download and run build script (via cmd line)
#     cold-boot
#     config Pi-Star app
#     reboot
#
#  Prepping initial (full) image:
#     welcome screen: hit 'next'
#     set country
#     create user (recommend pi-star/raspberry for starters)
#     select wifi (skip if wired)
#     choose browser (pick Firefox)
#     update software?
#     launch
#     open ssh window: download install script
#
#  Issues:
#    system requires cold boot after initial build_date (due to FSTAB rebuild?)
#    ShellInABox lacks a proper systemd unit file; difficult installation
#    libwx_baseu-3.0 routines missing: future fix?
#
#  Future:
#    $HOME?
#    Anydesk? VNC? PiConnect?
#    possibly config via raspi-config command line
#    APT listings: backports?
#    ICON's for desktop menu entries?
#
#  Download script:
#    cd /home/pi-star
#    wget -O Pi-Star-Gen-Gui.sh 'https://raw.githubusercontent.com/kn2tod/pistar-desktop/main/Pi-Star-Gen-Gui.sh'
#    sudo bash /home/pi-star/Pi-Star-Gen-Gui.sh
#
#  Restartable/Rerunnable (generaly/mostly?)

np=": "    # supress "continue" prompts (for selected steps)
opt=": "   # list/suppress option

pibase=${1:-mark}
pibase=${pibase,,[A-Z]}
pibase=${pibase/andy/AndyTaylorTweet}
pibase=${pibase/mw0mwz/AndyTaylorTweet}
pibase=${pibase/mark/kn2tod}
echo "Code Base: ${pibase}"

echo "==== Clean up from previous install: ====================================================================="
sudo apt --fix-broken install   # Just-in-case restarted
sudo apt update
sudo apt upgrade --fix-missing --fix-broken
sudo apt clean
sudo apt autoremove -y

${np} read -p "-- press any key to continue --" ipq

echo ""
echo "==== Install required system functions: =================================================================="
sudo apt install iptables            -y
sudo apt install iptables-persistent -y     # select "no"?
sudo apt install dnsutils            -y
sudo apt install xxd                 -y

sudo apt install bat                 -y     # optional: for dev
sudo apt install duf                 -y     # optional: for dev
sudo apt install ascii               -y     # optional: for dev
sudo apt install inxi                -y     # optional: for dev
sudo apt install lshw                -y     # optional: informational
sudo apt install hwinfo              -y     # optional: informational
sudo apt install hdparm              -y     # optional: informational
sudo apt install pydf                -y     # optional: informational
sudo apt install wavemon             -y     # optional: for testing/monitoring
sudo apt install shellcheck          -y     # optional: for dev
#sudo apt install apparmor apparmor-utils apparmor-profiles # ???

${np} read -p "-- press any key to continue --" ipq

echo ""
os=$(sed -n "s/VERSION_CODENAME=\(.*\)/\1/p" /etc/os-release)
echo -e "--> OS Version: ${os@u}"

echo ""
read -p "-- press any key to continue --" ipq

echo ""
echo "==== Install PHP/FPM: ===================================================================================="
phpv=8.4   # assume the lastest
if [ "$os" = "bullseye" ]; then phpv=7.4; fi
if [ "$os" = "bookworm" ]; then phpv=8.2; fi
if [ "$os" = "trixie" ];   then phpv=8.4; fi

#phpv=${os/buster/7.3}
#phpv=${os/bullseye/7.4}
#phpv=${os/bookworm/8.2}
#phpv=${os/trixie/8.4}

# check for valid $phpv?

echo "Installing PHP version ${phpv} for ${os@u}"

echo ""
read -p "-- press any key to continue --" ipq

sudo apt install php${phpv}-fpm      -y     # must install first
echo "---"
sudo apt install php${phpv}-cli      -y
echo "---"
sudo apt install php${phpv}          -y
echo "---"
sudo apt install php${phpv}-mbstring -y
echo "---"
sudo apt install php${phpv}-zip      -y
echo "---"
#sudo apt install php${phpv}-json     -y     # ????
sudo apt install php-json            -y
echo "---"
sudo dpkg-query -l | grep --color=auto -i "php"
echo "---"
sudo php --version

echo "---"
cd /etc/php/${phpv}/fpm/pool.d

sudo sed -i "s/^\(pm =\).*$/\1 dynamic/g"               www.conf
sudo sed -i "s/^\(pm.max_children =\).*$/\1 20/g"       www.conf
sudo sed -i "s/^\(pm.start_servers =\).*$/\1 8/g"       www.conf
sudo sed -i "s/^\(pm.min_spare_servers =\).*$/\1 4/g"   www.conf
sudo sed -i "s/^\(pm.max_spare_servers =\).*$/\1 8/g"   www.conf

sed -n '/^pm./p'                                        www.conf

echo "---"
${opt} cat www.conf
${opt} echo "---"

sudo systemctl               restart php${phpv}-fpm.service
sudo systemctl --no-pager -l status  php${phpv}-fpm.service

${np} read -p "-- press any key to continue --" ipq

echo ""
echo "==== Install NGINX: ======================================================================================"
sudo apt install nginx -y
echo "---"
sudo dpkg-query -l | grep --color=auto -i "nginx"
#if [ ! "$(grep -i 'mkdir' /lib/systemd/system/nginx.service)" ]; then
#  sudo sed -i '\/PIDFile=\/run\/nginx.pid/a ExecStartPre=\/bin\/mkdir -p \/var\/log\/nginx' /lib/systemd/system/nginx.service
#fi

echo ""

sudo systemctl daemon-reload
echo "---"
sudo nginx -t
echo "---"
sudo nginx -v
read -p "-- press any key to continue --" ipq

echo ""
#pibase="kn2tod"
#pibase="AndyTaylorTweet"
echo "Code Base: ${pibase}"
echo ""

echo "==== Load Pi-Star dashboard: ============================================================================="
cd /var/www
sudo git clone https://github.com/${pibase}/Pi-Star_DV_Dash dashboard
cd /var/www/dashboard
#sudo git remote set-url origin https://github.com/${pibase}/Pi-Star_DV_Dash.git
sudo git remote -v
sudo git pull    # just in case restarted

${np} read -p "-- press any key to continue --" ipq

echo ""
echo "==== Load Pi-Star s-binaries: ============================================================================"
cd /usr/local
sudo git clone https://github.com/${pibase}/Pi-Star_Binaries_sbin sbin
cd /usr/local/sbin
#sudo git remote set-url origin https://github.com/${pibase}/Pi-Star_Binaries_sbin.git
sudo git remote -v
sudo git pull    # just in case restarted
sudo chown root:staff /usr/local/sbin/*

${np} read -p "-- press any key to continue --" ipq

echo ""
echo "==== Load Pi-Star binaries: =============================================================================="
cd /usr/local
v4="v4"
if [ "${pibase}" == "AndyTaylorTweet" ]; then v4="v43"; fi
sudo git clone https://github.com/${pibase}/Pi-Star_${v4}_Binaries_Bin bin
cd /usr/local/bin
#sudo git remote set-url origin https://github.com/${pibase}/Pi-Star_v4_Binaries_Bin.git
sudo git remote -v
sudo git pull    # just in case restarted
sudo chown -R root:bin /usr/local/bin/*

${np} read -p "-- press any key to continue --" ipq

echo ""
echo "==== Load Pi-Star misc Application Files: ================================================================"
pibase="kn2tod"
cd /tmp
sudo git clone https://github.com/${pibase}/Pi-Star_Sysgen
cd /tmp/Pi-Star_Sysgen
#sudo git remote set-url origin https://github.com/${pibase}/Pi-Star_Sysgen.git
sudo git remote -v
sudo git pull    # just in case restarted

read -p "-- press any key to continue --" ipq

echo ""
echo "==== Configure NGINX for Pi-Star ========================================================================="
#sudo mkdir /etc/nginx/default.d   # ????

#cd /etc/nginx/sites-available
sudo cp /tmp/Pi-Star_Sysgen/misc/captive-portal /etc/nginx/sites-available
sudo cp /tmp/Pi-Star_Sysgen/misc/pi-star        /etc/nginx/sites-available

cd /etc/nginx/sites-enabled
sudo ln -s /etc/nginx/sites-available/pi-star pi-star
sudo ln -s /etc/nginx/sites-available/captive-portal captive-portal
sudo rm default   # ????
sudo ls -la

sudo mkdir /etc/nginx/default.d
cd /etc/nginx/default.d
sudo cp /tmp/Pi-Star_Sysgen/misc/index.conf     /etc/nginx/default.d
sudo cp /tmp/Pi-Star_Sysgen/misc/cacheing.conf  /etc/nginx/default.d
sudo cp /tmp/Pi-Star_Sysgen/misc/php.conf       /etc/nginx/default.d
sudo cp /tmp/Pi-Star_Sysgen/misc/security.conf  /etc/nginx/default.d

sudo sed -i "s/php[0-9.]*-/php${phpv}-/g"       /etc/nginx/default.d/php.conf
sudo sed -i 's/access_log \/var\/log\/nginx\/access.log;/#&\n\taccess_log off;/g' /etc/nginx/nginx.conf

echo ""
sudo nginx -t
echo ""
sudo systemctl               restart nginx
sudo systemctl --no-pager -l status  nginx

${np} read -p "-- press any key to continue --" ipq

echo ""
echo "==== Create dashboard userid/password: ==================================================================="
sudo apt install apache2-utils -y
echo "--"
sudo htpasswd -bc /var/www/.htpasswd pi-star raspberry
sudo chown www-data:www-data /var/www/.htpasswd
echo "--"
cat /var/www/.htpasswd
echo ""
read -p "-- press any key to continue --" ipq

echo ""
cd /home/pi-star
echo "==== Set Firewall: ======================================================================================="
sudo pistar-firewall >/dev/null
sudo cat /etc/iptables.rules  >> /etc/iptables/rules.v4
sudo cat /etc/ip6tables.rules >> /etc/iptables/rules.v6

ls -la /etc/iptables/*
${opt} echo "--"
${opt} sudo iptables -S

${np} read -p "-- press any key to continue --" ipq

echo ""
echo "==== Load initial host files (/local/etc): ==============================================================="
cd /usr/local/etc
sudo cp -R /tmp/Pi-Star_Sysgen/hostfiles/* /usr/local/etc
#sudo chown root:bin *
sudo chown www-data:www-data RSSI.dat
echo "Done!"

${np} read -p "-- press any key to continue --" ipq

echo ""
echo "==== Load initial host files (/etc): ====================================================================="
cd /etc
sudo cp /tmp/Pi-Star_Sysgen/initfiles/* /etc
echo "Done!"

${np} read -p "-- press any key to continue --" ipq

echo ""
echo "==== Set up rc.local: ===================================================================================="
sudo cp /tmp/Pi-Star_Sysgen/misc/rc.local    /etc
sudo chmod +x /etc/rc.local
ls -la /etc/rc.local
${opt} echo "--"
${opt} cat /etc/rc.local

read -p "-- press any key to continue --" ipq

echo ""
echo "==== Set up crontab entries: ============================================================================="
sudo cp /tmp/Pi-Star_Sysgen/misc/pistar-daily  /etc/cron.daily
sudo chmod +x /etc/cron.daily/pistar-daily
sudo cp /tmp/Pi-Star_Sysgen/misc/pistar-hourly /etc/cron.hourly
sudo chmod +x /etc/cron.hourly/pistar-hourly

cat -n /etc/crontab
echo "--cron.hourly:"
ls -la /etc/cron.hourly; 
echo "--cron.daily:"
ls -la /etc/cron.daily; 
echo "--cron.weekly:"
ls -la /etc/cron.weekly; 
echo "--cron.monthly:"
ls -la /etc/cron.monthly;

read -p "-- press any key to continue --" ipq

echo ""
echo "==== Install WiringPI: ==================================================================================="
cd /tmp

wpi="3.18"
deb="wiringpi_${wpi}_armhf.deb"
wget https://github.com/WiringPi/WiringPi/releases/download/${wpi}/${deb}
sudo dpkg -i /tmp/${deb}

echo "--"
sudo dpkg-query -l | grep --color=auto -i "wiring"

${np} read -p "-- press any key to continue --" ipq

echo ""
echo "==== Install misc GPIO libs =============================================================================="
sudo apt install rpi.gpio-common

echo "--"
sudo dpkg-query -l | grep --color=auto -i "gpio"

${np} read -p "-- press any key to continue --" ipq

echo ""
echo "==== Install ArduiPi_OLED: ==============================================================================="
cd /usr/local/lib
sudo rm libArdu*    2>/dev/null # just in case restarted
sudo rm ArduiP*     2>/dev/null # just in case restarted

sudo wget -O /usr/local/lib/libArduiPi_OLED.so.1.0 'http://HamOperator.com/files/libArduiPi_OLED.so.1.0'
sudo chmod 777 libArduiPi_OLED.so.1.0
sudo chown root:staff libArduiPi_OLED.so.1.0   # ????

# permissions?
sudo ln -sf /usr/local/lib/libArduiPi_OLED.so.1.0 libArduiPi_OLED.so.1
sudo ln -sf /usr/local/lib/libArduiPi_OLED.so.1   libArduiPi_OLED.so
sudo ln -sf libArduiPi_OLED.so.1.0                ArduiPi_OLED.so.1
sudo ldconfig
echo "---"
ls -la

read -p "-- press any key to continue --" ipq

echo ""
echo "==== create udev rules for gpio =========================================================================="
#sudo cp /tmp/Pi-Star_Sysgen/misc/99-gpio.rules    /etc/udev/rules.d   # ?????!!!!!?????
sudo cp /tmp/Pi-Star_Sysgen/misc/100-pistar.rules  /etc/udev/rules.d/   # for Icom TA 4100
sudo cp /tmp/Pi-Star_Sysgen/misc/98-pistar.rules   /etc/udev/rules.d

${opt} ls -la /etc/udev/rules.d
${opt} echo "--"
${opt} cat /etc/udev/rules.d/98-pistar.rules
${opt} echo "--"
${opt} cat /etc/udev/rules.d/100-pistar.rules

echo "---"
sudo systemctl restart               systemd-udevd
sudo systemctl status  --no-pager -l systemd-udevd
echo "---"
sudo udevadm control --reload-rules && sudo udevadm trigger

read -p "-- press any key to continue --" ipq

echo ""
echo "==== Create initial release info: ========================================================================"
# dummy this up for the moment:
build_date=$(date +%d-%b-%Y)
mmdvmhost=$(MMDVMHost -v | awk -F' ' '{print $3}')
kernel=$(uname -r)

sudo cp /tmp/Pi-Star_Sysgen/misc/pistar-release                  /etc/pistar-release

sudo sed -i "s/dd-mmm-yyyy/${build_date}/g"                      /etc/pistar-release
sudo sed -i "s/MMDVMHost = 20181222/MMDVMHost = ${mmdvmhost}/g"  /etc/pistar-release
sudo sed -i "s/unknown/${kernel}/g"                              /etc/pistar-release

cat /etc/pistar-release

read -p "-- press any key to continue --" ipq

echo ""
echo "==== Install Shell-in-a-Box: ============================================================================="
# MUST INSTALL BEFORE FSTAB MODS!

sudo rm -f /etc/default/shellinabox/options-enabled 2>/dev/null  # just in case restarted!

sudo apt install shellinabox   -y

echo ""
sudo sed -i 's/SHELLINABOX_PORT=.*/SHELLINABOX_PORT=2222/g' /etc/default/shellinabox
sudo sed -i '/SHELLINABOX_ARGS=/c SHELLINABOX_ARGS="--no-beep --disable-ssl-menu --disable-ssl --css=/etc/shellinabox/options-enabled/00_White\\ On\\ Black.css"' /etc/default/shellinabox

#cat /etc/default/shellinabox
sed -n 's/^SHELL/&/p' /etc/default/shellinabox

sudo cp /etc/pam.d/login /etc/pam.d/remote  # fix shell-in-a-box MOTD problem (Trixie)
sudo cp /tmp/Pi-Star_Sysgen/misc/issue   /etc/issue   # ????

sudo cp /tmp/Pi-Star_Sysgen/misc/shellinabox.service /lib/systemd/system/ 2>/dev/null
sudo systemctl daemon-reload
#sudo systemctl restart local-fs.target

echo ""
sudo systemctl               enable  shellinabox --now
sudo systemctl               restart shellinabox
sudo systemctl --no-pager -l status  shellinabox

cd /etc/shellinabox/options-available
if [ ! "$(grep -i "font-size:" '00_White On Black.css')" ]; then
  sudo sed -i 's/{$/&\n  font-size:        small;/g'                              '00_White On Black.css'
fi
if [ ! "$(grep -i "font-size:" '00+Black on White.css')" ]; then
  sudo sed -i 's/{$/&\n  font-size:        small;/g'                              '00+Black on White.css'
fi
if [ ! "$(grep -i "font-size:" '01+Color Terminal.css')" ]; then
  sudo sed -i 's/ {\( color: .*; \)}/ {\n  font-size:        small;\n \1\n  }/g'  '01+Color Terminal.css'
fi
if [ ! "$(grep -i "font-size:" 01_Monochrome.css)" ]; then
  sudo sed -i 's/ {\( color: .*; \)}/ {\n  font-size:        small;\n \1\n  }/g'   01_Monochrome.css
fi

echo "--"
sudo ssh -Q key
echo ""
#sudo sshd -T

read -p "-- press any key to continue --" ipq

echo ""
echo "==== Fix up FSTAB: ======================================================================================="
if [ ! "$(grep tmpfs /etc/fstab)" ] ; then
echo "--- modifying FSTAB:"
sudo sed -i.bak '$ s/$/\
tmpfs\t\t\t\/run\t\t\ttmpfs\tnodev,noatime,nosuid,mode=1777,size=32m\t\t0\t0\
tmpfs\t\t\t\/run\/lock\t\ttmpfs\tnodev,noatime,nosuid,mode=1777,size=5m\t\t0\t0\
tmpfs\t\t\t\/sys\/fs\/cgroup\t\ttmpfs\tnodev,noatime,nosuid\t\t\t\t0\t0\
tmpfs\t\t\t\/tmp\t\t\ttmpfs\tnodev,noatime,nosuid,mode=1777,size=128m\t0\t0\
tmpfs\t\t\t\/var\/log\t\ttmpfs\tnodev,noatime,nosuid,mode=0755,size=64m\t\t0\t0\
tmpfs\t\t\t\/var\/log\/nginx\t\ttmpfs\tnodev,noatime,nosuid,mode=0755,size=96k\t\t0\t0\
tmpfs\t\t\t\/var\/lib\/sudo\t\ttmpfs\tnodev,noatime,nosuid,mode=1777,size=16k\t\t0\t0\
tmpfs\t\t\t\/var\/lib\/dhcpcd\t\ttmpfs\tnodev,noatime,nosuid,mode=1777,size=32k\t\t0\t0\
#tmpfs\t\t\t\/var\/lib\/vnstat\t\ttmpfs\tnodev,noatime,nosuid,mode=1777,size=4m\t\t0\t0\
tmpfs\t\t\t\/var\/lib\/logrotate\ttmpfs\tnodev,noatime,nosuid,mode=0755,size=16k\t\t0\t0\
tmpfs\t\t\t\/var\/lib\/nginx\/body\ttmpfs\tnodev,noatime,nosuid,mode=1700,size=1m\t\t0\t0\
tmpfs\t\t\t\/var\/lib\/php\/sessions\ttmpfs\tnodev,noatime,nosuid,mode=0777,size=128k\t0\t0\
tmpfs\t\t\t\/var\/lib\/misc\t\ttmpfs\tnodev,noatime,nosuid,mode=1777,size=16k\t\t0\t0\
tmpfs\t\t\t\/var\/lib\/samba\/private\ttmpfs\tnodev,noatime,nosuid,mode=0755,size=4m\t\t0\t0\
tmpfs\t\t\t\/var\/cache\/samba\ttmpfs\tnodev,noatime,nosuid,mode=0755,size=1m\t\t0\t0\
/g' /etc/fstab
fi

cat /etc/fstab

echo ""
sudo findmnt --verify
echo ""
sudo systemctl daemon-reload
sudo mount --all

read -p "-- press any key to continue --" ipq

echo ""
echo "==== add groups/userid: =================================================================================="
#sudo useradd  mmdvm -g mmdvm -s /sbin/nologin
sudo usermod  pi-star -c "Pi-Star Master Account"
sudo usermod  -aG gpio    pi-star
sudo usermod  -aG dialout root
#sudo groupadd tty
#sudo usermod  -aG tty     pi-star   # ????

sudo groupadd mmdvm
sudo useradd  mmdvm -g mmdvm -c "MMDVM Service Account" -s /bin/bash
sudo usermod  -aG dialout mmdvm
#sudo usermod  -aG gpio    mmdvm
sudo usermod  -aG spi     mmdvm
sudo usermod  -aG i2c     mmdvm

echo "---"
cat /etc/passwd | grep "pi-star\|mmdvm"
echo "---"
cat /etc/subgid
echo "---"
sudo passwd -S -a
echo "---"
sudo pwck 2>/dev/null
echo "---"
getent passwd | cut -d: -f1 | while read name; do groups $name; done | awk -F: '{printf "%-20s %-50s\n", $1, $2}' | sort

read -p "-- press any key to continue --" ipq

echo ""
echo "==== modifying sudoers ==================================================================================="
#echo "SUDOERS: pi-star, www-data"
if [ ! "$(grep pi-star /etc/sudoers)"   ]; then
  echo "pi-star ALL=(ALL) NOPASSWD: ALL"  >> /etc/sudoers
fi
if [ ! "$(grep www-data /etc/sudoers)" ]; then
  echo "www-data ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi
if [ ! "$(grep !admin_flag /etc/sudoers)" ]; then
  echo -e "Defaults\t!admin_flag"         >> /etc/sudoers
fi

#echo "pi-star ALL=(ALL) NOPASSWD: ALL"  >> /etc/sudoers.d/010-pi-star
#echo "www-data ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/010-pi-star

#echo -e "Defaults\t\x21admin_flag"         > /tmp/010_no_admin_msgs
#sudo cp /tmp/010_no_admin_msgs /etc/sudoers.d/

#sudo sed -i 's/^@includedir/#&/g'          /etc/sudoers
#sudo sed -i 's/^Defaults.*use_pty/#&/g'   /etc/sudoers   # ????

#cat /etc/sudoers
#sudo sed -n '/^$/! p' /etc/sudoers
sudo grep -E "(^pi-star|^www-data|^Defaults)" /etc/sudoers

${np} read -p "-- press any key to continue --" ipq

echo ""
echo "==== modifying cmdline.txt ==============================================================================="

# ref: <https://michlstechblog.info/blog/linux-disable-assignment-of-new-names-for-network-interfaces/>
#sudo sed -i 's/.*$/& net.ifnames=0 biosdevname=0/g' /boot/cmdline.txt
#  remove biosdevname= ????

if [ ! "$(grep -i net.ifnames {/boot,/boot/firmware}/cmdline.txt 2>dev/null)" ]; then
  sudo sed -i.bak 's/ rootwait/ net.ifnames=0 rootwait/g'    /boot/cmdline.txt
  sudo sed -i.bak 's/ rootwait/ net.ifnames=0 rootwait/g'    /boot/firmware/cmdline.txt 2>/dev/null
fi

if [ ! "$(grep -i fsck.mode {/boot,/boot/firmware}/cmdline.txt 2>/dev/null)" ]; then
  sudo sed -i     's/ fsck.repair=yes /&fsck.mode=force /g'  /boot/cmdline.txt
  sudo sed -i     's/ fsck.repair=yes /&fsck.mode=force /g'  /boot/firmware/cmdline.txt 2>/dev/null
fi

# dwc_otg.lpm_enable=0 ??

sudo sed -i     's/console=serial0,115200 //g'               /boot/cmdline.txt                          # ?????
sudo sed -i     's/console=serial0,115200 //g'               /boot/firmware/cmdline.txt 2>/dev/null     # ?????

cat {/boot,/boot/firmware}/cmdline.txt 2>/dev/null
echo "---"

read -p "-- press any key to continue --" ipq

echo ""
echo "==== modifying config.txt ================================================================================"

if [ ! "$(grep enable_uart {/boot,/boot/firmware}/config.txt)" ]; then
sudo sed -i 's/\[all\]/&\
#enable_uart=1\
dtparam=i2c_arm=on\
dtparam=spi=on\
#dtoverlay=miniuart-bt\
#dtoverlay=disable-bt\
dtparam=uart0=on\
dtparam=uart1=on\
temp_limit=80\
# D2RG UART over SPI - for GPS?\
dtoverlay=sc16is752-spi0-ce0\
dtparam=pciex1\
dtparam=pciex1_gen=3\
usb_max_current_enable=1\
/g'  {/boot,/boot/firmware}/config.txt
fi

#[pi5]
#dtparam=fan_temp1=60000
#dtparam=fan_temp1_hyst=5000
#dtparam=fan_temp1_speed=50
#dtparam=fan_temp2=70000
#dtparam=fan_temp2_hyst=5000
#dtparam=fan_temp1_speed=100

#hdmi_force_hotplug=1\
#disable_overscan=1\
#hdmi_group=1\
#hdmi_mode=4\
#hdmi_enable_4kp60=1\

sudo sed -i 's/camera_auto_detect=0/camera_auto_detect=1/g' {/boot,/boot/firmware}/config.txt

${opt} cat /boot/config.txt
${opt} echo "---"
${opt} cat /boot/firmware/config.txt 2>/dev/null

ls -la {/boot,/boot/firmware}/config.txt
echo ""
grep -Ev "^[[:space:]]*#|^[[:space:]]*;|^$" /boot/firmware/config.txt

#sudo cp /tmp/Pi-Star_Sysgen/misc/sc16is752-spi0-ce0.dtb /boot/overlays/ 2>/dev/null
sudo chown root:root /boot/overlays/sc16is752-spi0-ce0.dtb

read -p "-- press any key to continue --" ipq

echo ""
echo "==== modifying /etc/modules =============================================================================="

if [ ! "$(grep -i spidev /etc/modules)" ]; then
  echo "spidev"                       >> /etc/modules
fi
if [ ! "$(grep -i xt_DSCP /etc/modules)" ]; then
  echo "xt_DSCP"                      >> /etc/modules
fi
if [ ! "$(grep -i i2c-dev /etc/modules)" ]; then
  echo "i2c-dev"                      >> /etc/modules
fi
if [ ! "$(grep -i ip_conntrack /etc/modules)" ]; then
  echo "ip_conntrack"                 >> /etc/modules
fi
if [ ! "$(grep -i ip_conntrack_ftp /etc/modules)" ]; then
  echo "ip_conntrack_ftp"             >> /etc/modules
fi

cat /etc/modules
echo "---"

${opt} read -p "-- press any key to continue --" ipq

echo ""
echo "==== Installing rsyslog =================================================================================="

# ref: <https://forums.raspberrypi.com/viewtopic.php?t=358028>

sudo apt install rsyslog             -y          # removed in Bookworm/Trixie!!!

# reboot req:
sudo sed -i '/GLOBAL DIRECTIVES/,/$/ s/###########################/&\
\
#\
# Use traditional timestamp format.\
# To enable high precision timestamps, comment out the following line.\
#\
$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat\
/g' /etc/rsyslog.conf

#sudo sed -i 's/boot.log/bootx.log/g' /etc/logrotate.d/bootlog     # makes boot.log persistent   ??????

${opt} echo "---"
#${opt} cat /etc/rsyslog.conf
echo "--"
sudo sed -n '/^#/! p' /etc/rsyslog.conf | sed '/^$/ d'

read -p "-- press any key to continue --" ipq

echo ""
echo "==== Load Pi-Star service tasks: ========================================================================="
cd /lib/systemd/system
sudo cp /tmp/Pi-Star_Sysgen/systemd/* /lib/systemd/system
#
#tasks=(pistar-watchdog pistar-remote pistar-upnp mmdvmhost dstarrepeater dmrgateway dmr2ysf dmr2nxdn dmr2m17 aprsgateway dapnetgateway dgidgateway ircddbgateway timercontrol timeserver ysfgateway ysf2dmr ysf2nxdn ysf2p25 ysfparrot p25gateway p25parrot nxdngateway nxdn2dmr nxdnparrot nextiondriver m17gateway gpsd mobilegps pistar-keeper mmdvm-log-restore mmdvm-log-backup mmdvm-log-backup-age)
tasks=(pistar-watchdog pistar-remote pistar-upnp mmdvmhost dstarrepeater dmrgateway dmr2ysf dmr2nxdn         aprsgateway dapnetgateway dgidgateway ircddbgateway timercontrol timeserver ysfgateway ysf2dmr ysf2nxdn ysf2p25 ysfparrot p25gateway p25parrot nxdngateway          nxdnparrot nextiondriver m17gateway      mobilegps               mmdvm-log-restore mmdvm-log-backup mmdvm-log-backup-age)

for task in ${tasks[*]}
do
  sudo systemctl enable $task.service
done
echo "   ${#tasks[*]} service units enabled"

${np} read -p "-- press any key to continue --" ipq

echo ""
echo "==== Load Pi-Star timer tasks: ==========================================================================="
timers=(aprsgateway dapnetgateway dgidgateway dmr2nxdn dmr2ysf dmrgateway dstarrepeater ircddbgateway m17gateway mmdvmhost mmdvm-log-backup-age mmdvm-log-backup nxdngateway nxdnparrot p25gateway p25parrot pistar-ap pistar-remote pistar-upnp pistar-watchdog timercontrol timeserver ysf2dmr ysf2nxdn ysf2p25 ysfgateway ysfparrot)

for task in ${timers[*]}
do
  sudo systemctl enable $task.timer
done
echo "   ${#timers[*]} timer units enabled"
echo ""

sudo systemctl daemon-reload

sudo systemctl disable pistar-upnp.service
sudo systemctl mask    pistar-upnp.service
sudo systemctl disable pistar-upnp.timer
sudo systemctl mask    pistar-upnp.timer

cd /home/pi-star
read -p "-- press any key to continue --" ipq

echo ""
echo "==== Build desktop menu items: ==========================================================================="
# test for dirs?
sudo cp /tmp/Pi-Star_Sysgen/misc/*.desktop /home/pi-star/.local/share/applications/
ls -la /home/pi-star/.local/share/applications
${np} read -p "-- press any key to continue --" ipq

echo ""
echo "==== Misc system configs: ================================================================================"
sudo cp /tmp/Pi-Star_Sysgen/misc/devpts /etc/default/   # just in case?
ls -la /etc/default

sudo cp /tmp/Pi-Star_Sysgen/misc/dstar-radio.mmdvmhost /etc   # things just work better with this starter config!
ls -la /etc/dstar*

${np} read -p "-- press any key to continue --" ipq

echo ""
echo "==== Create WiFi supplicant config: ======================================================================"
sudo cp /tmp/Pi-Star_Sysgen/misc/wpa_supplicant.conf /etc/wpa_supplicant/
ls -la /etc/wpa_supplicant/wpa*
echo "---"
cat /etc/wpa_supplicant/wpa_supplicant.conf

${np} read -p "-- press any key to continue --" ipq

echo ""
echo "==== Run host files update: =============================================================================="
sudo bash /usr/local/sbin/HostFilesUpdate.sh
ls -la /usr/local/etc/DMRids.d* 2>/dev/null
echo "# DMR Id's: $(wc -l /usr/local/etc/DMRIds.dat 2>/dev/null)"

${np} read -p "-- press any key to continue --" ipq

echo ""
echo "==== Create initial MOTD: ================================================================================"
sudo bash /usr/local/sbin/pistar-motdgen
echo "Done!"

${np} read -p "-- press any key to continue --" ipq

echo ""
echo "==== Set up AVAHI services ==============================================================================="
sudo cp /tmp/Pi-Star_Sysgen/misc/http.service /etc/avahi/services
sudo cp /tmp/Pi-Star_Sysgen/misc/ssh.service  /etc/avahi/services
ls -la /etc/avahi/services

#sudo sed -i 's/use-ipv6=yes/use-ipv6=no/g'                           /etc/avahi/avahi-daemon.conf
sudo sed -i 's/publish-hinfo=no/publish-hinfo=yes/g'                 /etc/avahi/avahi-daemon.conf
sudo sed -i 's/publish-workstation=no/publish-workstation=yes/g'     /etc/avahi/avahi-daemon.conf
cat /etc/avahi/avahi-daemon.conf

${np} read -p "-- press any key to continue --" ipq

echo ""
echo "==== Set some system nits ================================================================================"
#sudo sysctl fs.protected_regular=0
sudo sysctl fs.protected_regular=2

if ! [ $(cat /lib/systemd/system/nginx.service | grep -o "mkdir") ]; then
   sed -i '\/PIDFile=\/run\/nginx.pid/a ExecStartPre=\/bin\/mkdir -p \/var\/log\/nginx' /lib/systemd/system/nginx.service
   sduo systemctl               daemon-reload
   sudo systemctl               restart nginx.service
   sudo systemctl --no-pager -l status  nginx.service

fi

sudo systemctl enable                ssh.service   # just in case
sudo systemctl restart               ssh.service
sudo systemctl status  --no-pager -l ssh.service

${np} echo ""
${np} read -p "-- press any key to continue --" ipq

sudo mkdir -p /etc/rpi/swap.conf.d
sudo cp /tmp/Pi-Star_Sysgen/misc/90-disable-swap.conf /etc/rpi/swap.conf
echo "--zram disabled"

${np} echo ""
${np} read -p "-- press any key to continue --" ipq

echo ""
echo "==== Gen Time Stamps in boot dirs ========================================================================"
sudo rm {/boot,/boot/firmware}/$(hostname)-*   2>/dev/null   # get ride of previous timestamps
sudo touch {/boot,/boot/firmware}/$(hostname)-$(awk -F "= " '/Version/ {print $2}' /etc/pistar-release)-$(date "+%Y-%m-%d-%H%M%S")
sudo ls -la {/boot,/boot/firmware}/$(hostname)-*

echo ""

echo "==== Install Samba: ======================================================================================"
sudo apt install samba -y
echo "---"
sudo systemctl stop    smbd.service
sudo systemctl mask    smbd.service
#echo ""
#sudo smbstatus -v
${opt} echo ""
${opt} testparm -s # -v

read -p "-- press any key to continue --" ipq

echo ""
echo "Done!"

# Health check:
#   tests to make sure required tasks are running?

echo ""
read -p "--Recommended! Reboot (Y/n)? " ipq
if [ "$ipq" == "Y" ]; then
  history -a
# sudo poweroff   # COLD-START RECOMMENDED!
  sudo reboot     # COLD-START RECOMMENDED!
fi

exit

################################################################################################################
echo "==== Install Hostapd and support files ==================================================================="
sudo apt install hostapd             -y
sudo apt install dnsmasq             -y

sudo cp /tmp/Pi-Star_Sysgen/misc/interfaces               /etc/network/
sudo mkdir                                                /etc/network/interfaces.d    2>/dev/null
sudo cp /tmp/Pi-Star_Sysgen/misc/wlan0_ap                 /etc/network/interfaces.d/

cat     /tmp/Pi-Star_Sysgen/misc/dnsmasq.confwlan0_ap  >> /etc/dnsmasq.conf

echo ""

${np} read -p "-- press any key to continue --" ipq

################################################################################################################

#sudo rm -r /tmp/Pi-Star_Sysgen

echo "==== Miscellaneous tweaks to DHCPCD ======================================================================"
# for debugging/tracing:
sudo sed -i 's/RUN=".*"/RUN="yes"/g'                                                /etc/dhcp/debug

echo "==== Miscellaneous system tweaks ========================================================================="
sudo cp /tmp/Pi-Star_Sysgen/misc/40-ethernet  /lib/dhcpcd/dhcpcd-hooks/
sudo cp /tmp/Pi-Star_Sysgen/misc/50-wireless  /lib/dhcpcd/dhcpcd-hooks/
ls -la /lib/dhcpcd/dhcpcd-hooks

echo "==== Miscellaneous system tweaks ========================================================================="
# maybe?
echo -e "#!/bin/bash"                                         > /etc/network/if-up.d/pistar-motdgen
echo -e "#mount -o remount,rw /"                             >> /etc/network/if-up.d/pistar-motdgen
echo -e "/etc/init.d/procps restart"                         >> /etc/network/if-up.d/pistar-motdgen
echo -e "/usr/local/sbin/pistar-motdgen"                     >> /etc/network/if-up.d/pistar-motdgen
sudo chmod +x                                                   /etc/network/if-up.d/pistar-motdgen

if [ ! "$(grep dtdebug /boot/config.txt)" ]; then
  sudo sed -i 's/\[all\]/&\ndtdebug=on\n/g'  /boot/config.txt
fi
