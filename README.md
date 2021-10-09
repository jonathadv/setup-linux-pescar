# Setup Linux Pescar

Script to setup the system used during the class

> Customized for Linux Mint 20.2


### When testing a new Mint version

**Backup firefox profile:**


```bash
$ cd /home/pescar/.mozilla/firefox/
$ mv <profile> 'default_pescar_profile'
$ tar zcvf firefox_profile.tar.gz default_pescar_profile
```


**Packages to remember to install when testing a new Linux version**

```
openssh-client
openssh-server
openssh-sftp-server
ssh
vlc
chromium
vim
htop
cowsay
sl
fortunes-br
xgalaga
gnome-chess
lbreakout2
gimp
```

**Backup apt cache**
```bash
$ cd /var/cache
$ tar cvf apt.tar apt
```