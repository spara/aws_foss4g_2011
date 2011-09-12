#!/usr/bin/env bash
################################################################
#
# Amazon EC2 PostGIS 1.5 on RAID10,f2 EBS Array Build Script
#
# Complete Rip off of:
# http://github.com/tokumine/ebs_raid_postgis/blob/master/build.sh
# http://alestic.com/2009/06/ec2-ebs-raid
# http://biodivertido.blogspot.com/2009/10/install-postgresql-84-and-postgis-140.html
#
# Additional glue by Simon Tokumine, 15/11/09
# Additions by @spara, 10/08/10
#        added additional repos to sources.list
#        custom postgis, proj4, geos build
#        added packages for building postgis, proj4, geos
#        configured to build RAID10
#        customized for Canonical Ubuntu AMIs
# Additions by @spara, 1/13/11
#        updated for Ubuntu 10.10 Maverick Meerkat
#        region and instance-id taken from instance metadata
#        no. of volumes ($1) and size ($2) are now arguments
#        preseeded install for java and postfix
#        can now be run from a user data script
# Additions by @spara 1/14/11
#        permissions fixed
#        uses osm2pgsql package
#
# INSTALL ON Canonical UEC images: http://uec-images.ubuntu.com/releases/10.10/release/
# Tested on 64-bit AMI: ami-cef405a7 (Maverick)
#
# NOTE, THIS IS ONLY FOR TESTING
################################################################

################################################################
#SETUP
#Please complete the parts that are in []'s (over writing the []'s)
#then just run the script on the server
################################################################

# change this to you keypair and cert
export EC2_PRIVATE_KEY=[pk.pem]
export EC2_CERT=[cert.pem]
# change this to your instance
instanceid=$(GET http://169.254.169.254/latest/meta-data/instance-id)
# change to the instance's availability zone
availability_zone=$(GET http://169.254.169.254/latest/meta-data/placement/availability-zone)
# builds out RAID10, so size of RAID=volumes*size/2
volumes=$1
size=$2
# change to your mount point
mountpoint=/mnt/vol1
# change to a device
raid_array_location=/dev/md0
raid_level=10
raid_layout=f2
raid_chunk=256
postgres_password=postgres
# create a postgis template
db_name=template_postgis
################################################################

################################################################
# CREATE EBS VOLUMES & RAID ARRAY
################################################################
sudo apt-get -y install ec2-api-tools

devices=$(perl -e 'for$i("h".."k"){for$j("",1..15){print"/dev/sd$i$j\n"}}'|
head -$volumes)
devicearray=($devices)
volumeids=
i=1
while [ $i -le $volumes ]; do
   volumeid=$(ec2-create-volume -z $availability_zone --size $size | cut -f2)
   echo "$i: created $volumeid"
   device=${devicearray[$(($i-1))]}
   echo $volumeid
   ec2-attach-volume $volumeid -i $instanceid -d $device
   volumeids="$volumeids $volumeid"
   let i=i+1
done
echo "volumeids='$volumeids'"

sudo apt-get update 
echo "postfix	postfix/main_mailer_type select	No configuration" | sudo -E debconf-set-selections
sudo apt-get install -y mdadm xfsprogs

devices=$(perl -e 'for$i("h".."k"){for$j("",1..15){print"/dev/sd$i$j\n"}}'|
head -$volumes)

#builds out RAID10
yes | sudo mdadm \
--create $raid_array_location \
--chunk=$raid_chunk \
--level=$raid_level \
--layout=$raid_layout \
--metadata=1.1 \
--raid-devices $volumes \
$devices

echo DEVICE $devices | sudo tee /etc/mdadm.conf
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm.conf

sudo mkfs.xfs $raid_array_location

echo "$raid_array_location $mountpoint xfs noatime 0 0" | sudo tee -a /etc/fstab
sudo mkdir $mountpoint
sudo mount $mountpoint

################################################################
# INSTALL POSTGRES, POSTGIS & SETUP DATABASE ON RAID VOLUME
################################################################
sudo apt-get -y install libxml2-dev
sudo apt-get -y install postgresql-8.4 postgresql-server-dev-8.4 postgresql-contrib-8.4 libpq-dev
sudo /etc/init.d/postgresql-8.4 stop

# move data directory to RAID
sudo mkdir $mountpoint/data
sudo chmod -R 700 $mountpoint/data
sudo chown -R postgres.postgres $mountpoint/data
sudo -u postgres /usr/lib/postgresql/8.4/bin/initdb -D $mountpoint/data
sudo sed -i.bak -e 's/port = 5433/port = 5432/' /etc/postgresql/8.4/main/postgresql.conf
sudo sed -i.bak -e "s@\/var\/lib\/postgresql\/8.4\/main@$mountpoint\/data@" /etc/postgresql/8.4/main/postgresql.conf
sudo sed -i.bak -e 's/ssl = true/#ssl = true/' /etc/postgresql/8.4/main/postgresql.conf
sudo /etc/init.d/postgresql start

###############################################################
# INSTALL POSTGIS
###############################################################
# setup
cd /tmp
sudo apt-get -y install bzip2
sudo apt-get -y install g++
sudo apt-get -y install checkinstall

# install geos
wget http://download.osgeo.org/geos/geos-3.2.2.tar.bz2
bunzip2 geos-3.2.2.tar.bz2
tar xvf geos-3.2.2.tar
sudo chown -R ubuntu.ubuntu /tmp/geos-3.2.2
cd geos-3.2.2
./configure
make 
#sudo checkinstall --pkgname geos --pkgversion 3.2.2-src --default
sudo make install

# install proj
cd ../
wget http://download.osgeo.org/proj/proj-4.7.0.tar.gz
tar xvfz proj-4.7.0.tar.gz
cd proj-4.7.0
./configure
make 
#sudo checkinstall --pkgname proj4 --pkgversion 4.70-src --default
sudo make install
cd ../

# install postgis 
wget http://postgis.refractions.net/download/postgis-1.5.3.tar.gz
tar xvfz postgis-1.5.3.tar.gz
cd postgis-1.5.3
./configure
make 
#sudo checkinstall --pkgname postgis --pkgversion 1.5.2-src --default # remove with dpkg -r postgis
sudo make install
sudo /sbin/ldconfig

# config template_postgis
sudo -u postgres psql -c"ALTER user postgres WITH PASSWORD '$postgres_password'"
sudo -u postgres createdb $db_name
sudo -u postgres createlang -d$db_name plpgsql
sudo -u postgres psql -d$db_name -f /usr/share/postgresql/8.4/contrib/postgis-1.5/postgis.sql
sudo -u postgres psql -d$db_name -f /usr/share/postgresql/8.4/contrib/postgis-1.5/spatial_ref_sys.sql
sudo -u postgres psql -d$db_name -c"select postgis_lib_version();"

