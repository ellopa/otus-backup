#! /bin/bash

# Filesystem and mounting
sudo yum -y install parted
sudo parted -s /dev/sdb mklabel gpt
sudo parted /dev/sdb mkpart primary ext4 0% 100%
sudo mkfs.ext4 /dev/sdb1
mkdir /var/backup
sudo mount /dev/sdb1 /var/backup
cat /etc/mtab | grep /dev/sdb >> /etc/fstab

# Borg install and adjust
#sudo yum -y install epel-release
#sudo yum -y install borgbackup
#sudo yum -y install vim
#sudo useradd -m borg
#sudo mkdir /home/borg/.ssh
#sudo chmod 0700 /home/borg/.ssh/
#sudo cp /vagrant/authorized_keys /home/borg/.ssh/
#sudo cp /vagrant/hosts /etc/
#sudo chown borg:borg -R /home/borg
#sudo chmod 0600 /home/borg/.ssh/authorized_keys
#sudo chmod 700 /var/backup
#sudo chown borg:borg /var/backup
