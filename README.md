##  Настраиваем бэкапы

### Введение

BorgBackup это дедуплицирующая программа для резервного копирования. Опционально доступно сжатие и шифрование данных. Основная задача BorgBackup — предоставление эффективного и безопасного решения для резервного копирования. Благодаря дедупликации резервное копирование происходит очень быстро. Все данные можно зашифровать на стороне клиента, что делает Borg интересным для использования на арендованных хранилищах.

### Цели домашнего задани

Научиться использовать инструмент для резервного копирования

### Описание домашнего задания

- Настроить стенд Vagrant с двумя виртуальными машинами: backup_server и client.
- Настроить удаленный бэкап каталога /etc c сервера client при помощи borgbackup.

Резервные копии должны соответствовать следующим критериям:

- директория для резервных копий /var/backup. Это должна быть отдельная точка монтирования. В данном случае для демонстрации размер не принципиален, достаточно будет и 2GB;
- репозиторий для резервных копий должен быть зашифрован ключом или паролем - на ваше усмотрение;
- имя бэкапа должно содержать информацию о времени снятия бекапа;
- глубина бекапа должна быть год, хранить можно по последней копии на конец месяца, кроме последних трех. Последние три месяца должны содержать копии на каждый день. Т.е. должна
- быть правильно настроена политика удаления старых бэкапов;
- резервная копия снимается каждые 5 минут. Такой частый запуск в целях демонстрации;
- написан скрипт для снятия резервных копий. Скрипт запускается из соответствующей Cron джобы, либо systemd timer-а - на ваше усмотрение;
- настроено логирование процесса бекапа. Для упрощения можно весь вывод перенаправлять в logger с соответствующим тегом. Если настроите не в syslog, то обязательна ротация логов.


### Практические навыки - методика

- Установка и настройка стенда [VagrantFile](Vagrantfile_1). В итоге развернуто две машины:
  - backupserver 192.168.56.14 CentOS 7 
  - backupclient 192.168.56.13 CentOS 7
  
```
[root@backupserver ~]# lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0  40G  0 disk 
`-sda1   8:1    0  40G  0 part /
sdb      8:16   0   2G  0 disk 
`-sdb1   8:17   0   2G  0 part /var/backup
[root@backupserver ~]# df -h
Filesystem      Size  Used Avail Use% Mounted on
devtmpfs        237M     0  237M   0% /dev
tmpfs           244M     0  244M   0% /dev/shm
tmpfs           244M  4.5M  240M   2% /run
tmpfs           244M     0  244M   0% /sys/fs/cgroup
/dev/sda1        40G  3.2G   37G   8% /
/dev/sdb1       2.0G  6.0M  1.9G   1% /var/backup
tmpfs            49M     0   49M   0% /run/user/1000
```
- Подключаем EPEL репозиторий с дополнительными пакетами
```
sudo -i
```
```
[root@backupserver ~]# yum install epel-release
```
	
- Устанавливаем на backupserver и backupclient серверах borgbackup
```
[root@backupserver ~]# yum install borgbackup
Failed to set locale, defaulting to C
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
epel/x86_64/metalink                                                                            |  32 kB  00:00:00     
 * base: centos-mirror.rbc.ru
 * epel: mirror.logol.ru
 * extras: mirror.docker.ru
 * updates: mirror.docker.ru
epel                                                                                            | 4.7 kB  00:00:00     
(1/3): epel/x86_64/group_gz                                                                     | 100 kB  00:00:00     
(2/3): epel/x86_64/updateinfo                                                                   | 1.0 MB  00:00:00     
(3/3): epel/x86_64/primary_db                               

.......

Dependency Installed:
  libb2.x86_64 0:0.98.1-2.el7                              libzstd.x86_64 0:1.5.5-1.el7                               
  python3.x86_64 0:3.6.8-21.el7_9                          python3-libs.x86_64 0:3.6.8-21.el7_9                       
  python3-pip.noarch 0:9.0.3-8.el7                         python3-setuptools.noarch 0:39.2.0-10.el7                  
  python36-llfuse.x86_64 0:1.0-2.el7                       python36-msgpack.x86_64 0:0.5.6-5.el7                      
  python36-packaging.noarch 0:16.8-6.el7                   python36-pyparsing.noarch 0:2.4.0-1.el7                    
  python36-six.noarch 0:1.14.0-3.el7                       xxhash-libs.x86_64 0:0.8.2-1.el7                           

Complete!
```
```
[root@backupclient ~]# yum install borgbackup
Failed to set locale, defaulting to C
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
epel/x86_64/metalink                                                                            |  32 kB  00:00:00     
 * base: mirror.docker.ru
 * epel: fedora-mirror02.rbc.ru
 * extras: mirror.docker.ru
 * updates: mirror.yandex.ru
epel                                                                                            | 4.7 kB  00:00:00     
(1/3): epel/x86_64/group_gz                                                                     | 100 kB  00:00:00     
(2/3): epel/x86_64/updateinfo                                                                   | 1.0 MB  00:00:00     
(3/3): epel/x86_64/primary_db                                                                   | 7.0 MB  00:00:00     
Resolving Dependencies
--> Running transaction check
---> Package borgbackup.x86_64 0:1.1.18-2.el7 will be installed
--> Processing Dependency: python(abi) = 3.6 for package: borgbackup-1.1.18-2.el7.x86_64
--> Processing Dependency: python36-msgpack <= 0.5.6 for package: borgbackup-1.1.18-2.el7.x86_64
--> Processing Dependency: /usr/bin/python3 for package: borgbackup-1.1.18-2.el7.x86_64
--> Processing Dependency: python36-llfuse for package: borgbackup-1.1.18-2.el7.x86_64
--> Processing Dependency: python36-packaging for package: borgbackup-1.1.18-2.el7.x86_64
--> Processing Dependency: python36-setuptools for package: borgbackup-1.1.18-2.el7.x86_64
--> Processing Dependency: libb2.so.1()(64bit) for package: borgbackup-1.1.18-2.el7.x86_64

....
Installed:
  borgbackup.x86_64 0:1.1.18-2.el7                                                                                     

Dependency Installed:
  libb2.x86_64 0:0.98.1-2.el7                              libzstd.x86_64 0:1.5.5-1.el7                               
  python3.x86_64 0:3.6.8-21.el7_9                          python3-libs.x86_64 0:3.6.8-21.el7_9                       
  python3-pip.noarch 0:9.0.3-8.el7                         python3-setuptools.noarch 0:39.2.0-10.el7                  
  python36-llfuse.x86_64 0:1.0-2.el7                       python36-msgpack.x86_64 0:0.5.6-5.el7                      
  python36-packaging.noarch 0:16.8-6.el7                   python36-pyparsing.noarch 0:2.4.0-1.el7                    
  python36-six.noarch 0:1.14.0-3.el7                       xxhash-libs.x86_64 0:0.8.2-1.el7                           

Complete!
```
- На сервере backupserver создаем пользователя borg и каталог /var/backup/client и назначаем на него права пользователя borg

```
[root@backupserver ~]# useradd -m borg
[root@backupserver ~]# sudo -i -u borg
[root@backupserver ~]# chown borg:borg -R /var/backup/
[borg@backupserver ~]$ mkdir /var/backup/client
[borg@backupserver ~]$ mkdir .ssh
[borg@backupserver ~]$ touch .ssh/authorized_keys
[borg@backupserver ~]$ chmod 700 .ssh
[borg@backupserver ~]$ chmod 600 .ssh/authorized_keys
```
- Генерируем пару ключей 
>- Passphrase - Ключевая фраза похожа на пароль. Однако пароль обычно относится к чему-либо, используемому для аутентификации или входа в систему. Ключевая фраза обычно относится к секрету, используемому для защиты ключа шифрования. Обычно фактический ключ шифрования выводится из парольной фразы и используется для шифрования защищаемого ресурса.
>- **Можно просто нажать Enter и пропустить этот шаг. Или ввести passphrase — тогда его нужно будет вводить каждый раз, когда используется ключ.**
>- Для этого ДЗ passphrase Otus!2420
 
```
[root@backupclient ~]# ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa): 
Created directory '/root/.ssh'.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /root/.ssh/id_rsa.
Your public key has been saved in /root/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:4B5VE3LVmXk1913TMQmh0sS4A+BbRrB68hMaBrbDcMs root@backupclient
The key's randomart image is:
+---[RSA 2048]----+
|     oo.. B+.+oOO|
|    . o. =oo. =.@|
|.o.  o.oo..o   .o|
|+oo...+o o.      |
| +E= +o S .      |
|  o *...         |
|   . o.          |
|      .          |
|                 |
+----[SHA256]-----+

```
- Скопировать публичный ключ на сервер 
```
[root@backupclient ~]# ssh-copy-id -i /root/.ssh/id_rsa.pub borg@192.168.56.14                 
/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/root/.ssh/id_rsa.pub"
/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
Enter passphrase for key '/root/.ssh/id_rsa': 
Enter passphrase for key '/root/.ssh/id_rsa': 
Enter passphrase for key '/root/.ssh/id_rsa': 
/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
Enter passphrase for key '/root/.ssh/id_rsa': 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'borg@192.168.56.14'"
and check to make sure that only the key(s) you wanted were added.
```
- Проверка подключения
```
[root@backupclient ~]# ssh borg@192.168.56.14
Enter passphrase for key '/root/.ssh/id_rsa': 
```
- Инициализируем репозиторий borg на backup сервере с client сервера:
```
borg init --encryption=repokey borg@192.168.56.14:/var/backup/client
```
```
[root@backupclient ~]# borg init --encryption=repokey borg@192.168.56.14:/var/backup/client
Enter passphrase for key '/root/.ssh/id_rsa': 
Enter new passphrase: 
Enter same passphrase again: 
Do you want your passphrase to be displayed for verification? [yN]: N

By default repositories initialized with this version will produce security
errors if written to with an older version (up to and including Borg 1.0.8).

If you want to use these older versions, you can disable the check by running:
borg upgrade --disable-tam ssh://borg@192.168.56.14/var/backup/client

See https://borgbackup.readthedocs.io/en/stable/changes.html#pre-1-0-9-manifest-spoofing-vulnerability for details about the security implications.

IMPORTANT: you will need both KEY AND PASSPHRASE to access this repo!
If you used a repokey mode, the key is stored in the repo, but you should back it up separately.
Use "borg key export" to export the key, optionally in printable format.
Write down the passphrase. Store both at safe place(s).
```
- Запускаем создания бэкапа
```
borg create --stats --list borg@192.168.56.14:/var/backup/client::"etc-{now:%Y-%m-%d_%H:%M:%S}" /etc
Enter passphrase for key '/root/.ssh/id_rsa': 
Enter passphrase for key ssh://borg@192.168.56.14/var/backup/client: 
A /etc/crypttab

......

------------------------------------------------------------------------------
Archive name: etc-2024-03-02_05:08:42
Archive fingerprint: 4ddf665746b6d869dd618a3ac62005dd7b41730dac2bb9eba836a2738410b5a4
Time (start): Sat, 2024-03-02 05:09:12
Time (end):   Sat, 2024-03-02 05:09:14
Duration: 2.16 seconds
Number of files: 1698
Utilization of max. archive size: 0%
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
This archive:               28.43 MB             13.49 MB             11.84 MB
All archives:               28.43 MB             13.49 MB             11.84 MB

                       Unique chunks         Total chunks
Chunk index:                    1277                 1692
------------------------------------------------------------------------------
```

- Просмотр бэкапов
```
[root@backupclient ~]# borg list borg@192.168.56.14:/var/backup/client                                  
Enter passphrase for key '/root/.ssh/id_rsa': 
Enter passphrase for key ssh://borg@192.168.56.14/var/backup/client: 
etc-2024-03-02_05:08:42              Sat, 2024-03-02 05:09:12 [4ddf665746b6d869dd618a3ac62005dd7b41730dac2bb9eba836a2738410b5a4]

```
```
[root@backupclient borg_test_dir]# borg list borg@192.168.56.14:/var/backup/client        
Enter passphrase for key '/root/.ssh/id_rsa': 
Enter passphrase for key ssh://borg@192.168.56.14/var/backup/client: 
etc-2024-03-02_05:08:42              Sat, 2024-03-02 05:09:12 [4ddf665746b6d869dd618a3ac62005dd7b41730dac2bb9eba836a2738410b5a4]
etc-2024-03-03_08:25:10              Sun, 2024-03-03 08:25:34 [39cafd4976f3d40ab04f65e089434b92e2980408a470d3a0c79c5e1eafdd6332]
```
```
[root@backupclient ~]# borg info borg@192.168.56.14:/var/backup/client
Enter passphrase for key '/root/.ssh/id_rsa': 
Enter passphrase for key ssh://borg@192.168.56.14/var/backup/client: 
Repository ID: e238b1466167cdb3de4905c392ac662cadfa462506ff14406af0d1a7b2558591
Location: ssh://borg@192.168.56.14/var/backup/client
Encrypted: Yes (repokey)
Cache: /root/.cache/borg/e238b1466167cdb3de4905c392ac662cadfa462506ff14406af0d1a7b2558591
Security dir: /root/.config/borg/security/e238b1466167cdb3de4905c392ac662cadfa462506ff14406af0d1a7b2558591
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
All archives:               28.43 MB             13.49 MB             11.84 MB

                       Unique chunks         Total chunks
Chunk index:                    1277                 1692
```
-  Просмотр бэкапа etc-2024-03-02_05:08:42
```
borg list borg@192.168.56.14:/var/backup/client::etc-2024-03-02_05:08:42
borg info borg@192.168.56.14:/var/backup/client::etc-2024-03-02_05:08:42
```
- Проверка на целостность репозитория/архива
```
borg check -v borg@192.168.56.14:/var/backup/client
borg check -v borg@192.168.56.14:/var/backup/client::etc-2024-03-02_05:08:42
```
- Достаем файл из бекапа
```
[root@backupclient borg_test_dir]# borg extract --list --dry-run ssh://borg@192.168.56.14/var/backup/client::etc-2024-03-02_05:08:42 etc/hostname
Enter passphrase for key '/root/.ssh/id_rsa': 
Enter passphrase for key ssh://borg@192.168.56.14/var/backup/client: 
Warning: File system encoding is "ascii", extracting non-ascii filenames will not be supported.
Hint: You likely need to fix your locale setup. E.g. install locales and use: LANG=en_US.UTF-8
etc/hostname
```
### Выполнение домашнего задания - автоматизация

- Развернем стенд с помощью [Vagrant](Vagrantfile) и [Ansible](playbook.yml), которые подготовят для нас окружение и запустят бекап

```bash
vagrant up --no-provision
ANSIBLE_ARGS='--skip-tags="client"' vagrant provision
ANSIBLE_ARGS='--tags="client"' vagrant provision client

```
>- Ключ шифрования и частоту бекапа можно задать в ./host_vars/client

- Оставить стенд поработать.
- Проверка лога на клиенте 

```bash
vagrant ssh client
sudo -i
cat /var/log/messages | grep borg
```
```
se state=started masked=None scope=system
Mar  3 15:38:30 localhost borg: ------------------------------------------------------------------------------
Mar  3 15:38:30 localhost borg: Archive name: etc-2024-03-03_15:38:28
Mar  3 15:38:30 localhost borg: Archive fingerprint: bc3fe402dbefa53f929b184631cc68d70b62a35ec75dea73138b4c62511992ed
Mar  3 15:38:30 localhost borg: Time (start): Sun, 2024-03-03 15:38:29
Mar  3 15:38:30 localhost borg: Time (end):   Sun, 2024-03-03 15:38:30
Mar  3 15:38:30 localhost borg: Duration: 1.01 seconds
Mar  3 15:38:30 localhost borg: Number of files: 1700
Mar  3 15:38:30 localhost borg: Utilization of max. archive size: 0%
Mar  3 15:38:30 localhost borg: ------------------------------------------------------------------------------
Mar  3 15:38:30 localhost borg: Original size      Compressed size    Deduplicated size
Mar  3 15:38:30 localhost borg: This archive:               28.43 MB             13.49 MB             11.84 MB
Mar  3 15:38:30 localhost borg: All archives:               28.43 MB             13.49 MB             11.84 MB
Mar  3 15:38:30 localhost borg: Unique chunks         Total chunks
Mar  3 15:38:30 localhost borg: Chunk index:                    1284                 1700
Mar  3 15:38:30 localhost borg: ------------------------------------------------------------------------------
Mar  3 15:43:47 localhost borg: ------------------------------------------------------------------------------
Mar  3 15:43:47 localhost borg: Archive name: etc-2024-03-03_15:43:46
Mar  3 15:43:47 localhost borg: Archive fingerprint: 216efecb40ac2d655fb8604e77537a40cac28d4e821441b8c12586e72c8119cf
Mar  3 15:43:47 localhost borg: Time (start): Sun, 2024-03-03 15:43:47
Mar  3 15:43:47 localhost borg: Time (end):   Sun, 2024-03-03 15:43:47
Mar  3 15:43:47 localhost borg: Duration: 0.25 seconds
Mar  3 15:43:47 localhost borg: Number of files: 1700
Mar  3 15:43:47 localhost borg: Utilization of max. archive size: 0%
Mar  3 15:43:47 localhost borg: ------------------------------------------------------------------------------
Mar  3 15:43:47 localhost borg: Original size      Compressed size    Deduplicated size
Mar  3 15:43:47 localhost borg: This archive:               28.43 MB             13.49 MB            125.53 kB
Mar  3 15:43:47 localhost borg: All archives:               56.85 MB             26.98 MB             11.97 MB
Mar  3 15:43:47 localhost borg: Unique chunks         Total chunks
Mar  3 15:43:47 localhost borg: Chunk index:                    1288                 3396
Mar  3 15:43:47 localhost borg: ------------------------------------------------------------------------------
Mar  3 15:49:47 localhost borg: ------------------------------------------------------------------------------
Mar  3 15:49:47 localhost borg: Archive name: etc-2024-03-03_15:49:46
Mar  3 15:49:47 localhost borg: Archive fingerprint: 33febac290f7efe5ece64eee11b881d928578ae362f1bdfcf653e9eed24c2ca6
Mar  3 15:49:47 localhost borg: Time (start): Sun, 2024-03-03 15:49:47
Mar  3 15:49:47 localhost borg: Time (end):   Sun, 2024-03-03 15:49:47
Mar  3 15:49:47 localhost borg: Duration: 0.25 seconds
Mar  3 15:49:47 localhost borg: Number of files: 1700
Mar  3 15:49:47 localhost borg: Utilization of max. archive size: 0%
Mar  3 15:49:47 localhost borg: ------------------------------------------------------------------------------
Mar  3 15:49:47 localhost borg: Original size      Compressed size    Deduplicated size
Mar  3 15:49:47 localhost borg: This archive:               28.43 MB             13.49 MB                583 B
Mar  3 15:49:47 localhost borg: All archives:               56.85 MB             26.99 MB             11.84 MB
Mar  3 15:49:47 localhost borg: Unique chunks         Total chunks
Mar  3 15:49:47 localhost borg: Chunk index:                    1281                 3392
Mar  3 15:49:47 localhost borg: ------------------------------------------------------------------------------
Mar  3 15:55:47 localhost borg: ------------------------------------------------------------------------------
Mar  3 15:55:47 localhost borg: Archive name: etc-2024-03-03_15:55:46
Mar  3 15:55:47 localhost borg: Archive fingerprint: 8821814c386eaff296d844149de7b079dd3d55c2f22c3e9971a28bb27d744131
Mar  3 15:55:47 localhost borg: Time (start): Sun, 2024-03-03 15:55:47
Mar  3 15:55:47 localhost borg: Time (end):   Sun, 2024-03-03 15:55:47
Mar  3 15:55:47 localhost borg: Duration: 0.23 seconds
Mar  3 15:55:47 localhost borg: Number of files: 1700
Mar  3 15:55:47 localhost borg: Utilization of max. archive size: 0%
Mar  3 15:55:47 localhost borg: ------------------------------------------------------------------------------
Mar  3 15:55:47 localhost borg: Original size      Compressed size    Deduplicated size
Mar  3 15:55:47 localhost borg: This archive:               28.43 MB             13.49 MB                583 B
Mar  3 15:55:47 localhost borg: All archives:               56.85 MB             26.99 MB             11.84 MB
Mar  3 15:55:47 localhost borg: Unique chunks         Total chunks
Mar  3 15:55:47 localhost borg: Chunk index:                    1281                 3392
Mar  3 15:55:47 localhost borg: ------------------------------------------------------------------------------
Mar  3 16:01:03 localhost borg: ------------------------------------------------------------------------------
Mar  3 16:01:03 localhost borg: Archive name: etc-2024-03-03_16:01:02
Mar  3 16:01:03 localhost borg: Archive fingerprint: 49bead5f17ca2ec6220667af86be45fd37af5782edc319ad78b577d648102d89
Mar  3 16:01:03 localhost borg: Time (start): Sun, 2024-03-03 16:01:02
Mar  3 16:01:03 localhost borg: Time (end):   Sun, 2024-03-03 16:01:02
Mar  3 16:01:03 localhost borg: Duration: 0.25 seconds
Mar  3 16:01:03 localhost borg: Number of files: 1700
Mar  3 16:01:03 localhost borg: Utilization of max. archive size: 0%
Mar  3 16:01:03 localhost borg: ------------------------------------------------------------------------------
Mar  3 16:01:03 localhost borg: Original size      Compressed size    Deduplicated size
Mar  3 16:01:03 localhost borg: This archive:               28.43 MB             13.49 MB                583 B
Mar  3 16:01:03 localhost borg: All archives:               56.85 MB             26.99 MB             11.84 MB
Mar  3 16:01:03 localhost borg: Unique chunks         Total chunks
Mar  3 16:01:03 localhost borg: Chunk index:                    1281                 3392
Mar  3 16:01:03 localhost borg: ------------------------------------------------------------------------------

```
- Последний созданный бекап
```bash
[root@client ~]# BORG_PASSPHRASE='Otus!2420' borg list borg@192.168.56.14:/var/backup/ 
etc-2024-03-03_17:11:11              Sun, 2024-03-03 17:11:12 [f05c3faebbe5f4c6d16d62c881485d306ece94d943dd4a5bfa198e1b0b39fe13]
```
- Просмотр списка файлов
```bash
[root@client ~]# BORG_PASSPHRASE='Otus!2420' borg list borg@192.168.56.14:/var/backup/::etc-2024-03-03_17:11:11  | head -n 10
drwxr-xr-x root   root          0 Sun, 2024-03-03 16:41:19 etc
-rw------- root   root          0 Thu, 2020-04-30 22:04:55 etc/crypttab
lrwxrwxrwx root   root         17 Thu, 2020-04-30 22:04:55 etc/mtab -> /proc/self/mounts
-rw-r--r-- root   root          7 Sun, 2024-03-03 16:39:17 etc/hostname
-rw-r--r-- root   root       2388 Thu, 2020-04-30 22:08:36 etc/libuser.conf
-rw-r--r-- root   root       2043 Thu, 2020-04-30 22:08:36 etc/login.defs
-rw-r--r-- root   root         37 Thu, 2020-04-30 22:08:36 etc/vconsole.conf
lrwxrwxrwx root   root         25 Thu, 2020-04-30 22:08:36 etc/localtime -> ../usr/share/zoneinfo/UTC
-rw-r--r-- root   root         19 Thu, 2020-04-30 22:08:36 etc/locale.conf
-rw-r--r-- root   root        450 Sun, 2024-03-03 16:39:23 etc/fstab

```
```
[root@client ~]# systemctl list-timers --all
NEXT                         LEFT         LAST PASSED UNIT                         ACTIVATES
Sun 2024-03-03 16:47:06 UTC  1min 6s left n/a  n/a    borg-backup.timer            borg-backup.service
Sun 2024-03-03 16:54:00 UTC  8min left    n/a  n/a    systemd-tmpfiles-clean.timer systemd-tmpfiles-clean.service
n/a                          n/a          n/a  n/a    systemd-readahead-done.timer systemd-readahead-done.service
```
- Остановка бекапа
```bash
systemctl stop borg-backup.timer
```
- **Восстановление директории /etc из бекапа**
```
[root@client ~]# cd                                                                            
[root@client ~]# BORG_PASSPHRASE='Otus!2420' borg extract  borg@192.168.56.14:/var/backup/::etc-2024-03-03_17:11:11 etc
Warning: File system encoding is "ascii", extracting non-ascii filenames will not be supported.
Hint: You likely need to fix your locale setup. E.g. install locales and use: LANG=en_US.UTF-8
[root@client ~]# ls /etc/ | wc -l
180
[root@client ~]# rm -rf /etc/
rm: cannot remove '/etc/': Device or resource busy
[root@client ~]# ls /etc/ | wc -l
0
[root@client ~]# cp -Rf etc/* /etc/
[root@client ~]# ls /etc/ | wc -l
180
```
