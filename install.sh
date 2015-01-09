#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

version=10.0.14
xtrabackupversion=2.2.7-5050
mycnf=$1
target=$(pwd)
user=$(whoami)

homedir=$target/mariadb-galera-$version
datadir=$homedir/data
binlogsdir=$homedir/binlogs
confdir=$homedir/conf
basedir=$homedir/mariadb
xtrabackupdir=$homedir/xtrabackup
logsdir=$homedir/logs
mycnfpath=$confdir/my.cnf

echo "Creating directories..."
mkdir -p $homedir
mkdir -p $datadir
mkdir -p $confdir
mkdir -p $basedir
mkdir -p $logsdir
mkdir -p $binlogsdir
mkdir -p $xtrabackupdir

# get tarball
echo "Pulling MariaDB Galera $version..."

echo "Pulling Percona Xtrabackup $xtrabackupversion..."

# extract files
echo "Extracting MariaDB Galera files..."
tar zxf mariadb-galera-$version.tar.gz -C $basedir --strip-components 1


echo "Extracting Percona Xtrabackup files..."
tar zxf percona-xtrabackup-$xtrabackupversion-Linux-x86_64.tar.gz -C $xtrabackupdir --strip-components 1

echo "Setting my.cnf..."
#cp $mycnf $confdir/my.cnf
cat base-my.cnf $mycnf > $confdir/my.cnf
rm -rf /home/$user/.my.cnf
ln -s $confdir/my.cnf /home/$user/.my.cnf

sed -i 's|\$basedir|'$basedir'|g' $mycnfpath
sed -i 's|\$homedir|'$homedir'|g' $mycnfpath
sed -i 's|\$datadir|'$datadir'|g' $mycnfpath
sed -i 's|\$confdir|'$confdir'|g' $mycnfpath
sed -i 's|\$logsdir|'$logsdir'|g' $mycnfpath
sed -i 's|\$user|'$user'|g' $mycnfpath

echo "Preparing mysql.server script..."
cp $basedir/support-files/mysql.server $homedir/server
sed -i 's|/usr/local/mysql/data|'$datadir'|g' $homedir/server
sed -i 's|/usr/local/mysql|'$basedir'|g' $homedir/server

echo "Preparing Xtrabackup..."
for binary in $(ls $xtrabackupdir/bin); do mv $xtrabackupdir/bin/$binary $basedir/bin/$binary; done
rm -rf $xtrabackupdir

echo "Initializing MariaDB data directory..."
$basedir/scripts/mysql_install_db --defaults-file=$mycnfpath --user=$user --basedir=$basedir --datadir=$datadir 

ln -s $confdir/my.cnf $basedir/my.cnf