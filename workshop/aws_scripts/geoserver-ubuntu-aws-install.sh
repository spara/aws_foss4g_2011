#
# install Geoserver on Ubuntu Maverick 10.10
# note: Geoserver is proxied through apache so port 8080 is not used
#
# @spara 11/15/10
#

# setup sources 
sudo sh -c "echo ' ' >> /etc/apt/sources.list"
sudo sh -c "echo 'deb http://us.archive.ubuntu.com/ubuntu/ maverick multiverse' >> /etc/apt/sources.list"
sudo sh -c "echo 'deb-src http://us.archive.ubuntu.com/ubuntu/ maverick multiverse' >> /etc/apt/sources.list"
sudo sh -c "echo 'deb http://us.archive.ubuntu.com/ubuntu/ maverick-updates multiverse' >> /etc/apt/sources.list"
sudo sh -c "echo 'deb-src http://us.archive.ubuntu.com/ubuntu/ maverick-updates multiverse' >> /etc/apt/sources.list"
sudo sh -c "echo 'deb http://archive.canonical.com/ maverick partner' >> /etc/apt/sources.list"
sudo apt-get update

# magic! (installs java without physically accepting license
echo "sun-java6-jdk shared/accepted-sun-dlj-v1-1 boolean true" | sudo -E debconf-set-selections

# setup prerequisites 
sudo apt-get -y install sun-java6-bin
export JAVA_HOME=/usr/lib/jvm/java-6-sun
sudo apt-get -y install unzip

# set java paths
sudo touch /etc/profile.d/java.sh
sudo sh -c "echo 'export JAVA_HOME=/usr/lib/jvm/java-6-sun' >> /etc/profile.d/java.sh"
sudo sh -c "echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /etc/profile.d/java.sh"
sudo source /etc/profile.d/java.sh
export JAVA_HOME=/usr/lib/jvm/java-6-sun
export PATH=$PATH:$JAVA_HOME/bin

#install tomcat6
sudo apt-get install -y tomcat6
sudo chgrp -R tomcat6 /etc/tomcat6
sudo chmod -R g+w /etc/tomcat6

# install and config apache
sudo apt-get install -y apache2
sudo ln -s /etc/apache2/mods-available/proxy.conf /etc/apache2/mods-enabled/proxy.conf
sudo ln -s /etc/apache2/mods-available/proxy.load /etc/apache2/mods-enabled/proxy.load
sudo ln -s /etc/apache2/mods-available/proxy_http.load /etc/apache2/mods-enabled/proxy_http.load

# add tomcat proxy
sudo chmod 666 /etc/apache2/sites-available/default
sudo sed -i '$d'  /etc/apache2/sites-available/default
sudo sh -c "echo ' ' >> /etc/apache2/sites-available/default"
sudo sh -c "echo 'ProxyRequests Off' >> /etc/apache2/sites-available/default"
sudo sh -c "echo '# Remember to turn the next line off if you are proxying to a NameVirtualHost' >> /etc/apache2/sites-available/default"
sudo sh -c "echo 'ProxyPreserveHost On' >> /etc/apache2/sites-available/default"
sudo sh -c "echo ' ' >> /etc/apache2/sites-available/default"
sudo sh -c "echo '<Proxy *>' >> /etc/apache2/sites-available/default"
sudo sh -c "echo '    Order deny,allow' >> /etc/apache2/sites-available/default"
sudo sh -c "echo '    Allow from all' >> /etc/apache2/sites-available/default"
sudo sh -c "echo '</Proxy>' >> /etc/apache2/sites-available/default"
sudo sh -c "echo ' ' >> /etc/apache2/sites-available/default"
sudo sh -c "echo 'ProxyPass /geoserver http://localhost:8080/geoserver' >> /etc/apache2/sites-available/default"
sudo sh -c "echo 'ProxyPassReverse /geoserver http://localhost:8080/geoserver' >> /etc/apache2/sites-available/default"
sudo sh -c "echo ' ' >> /etc/apache2/sites-available/default"
sudo sh -c "echo '</VirtualHost>' >> /etc/apache2/sites-available/default"
sudo chmod 644 /etc/apache2/sites-available/default

# get geoserver, change to version you want
sudo service tomcat6 stop
wget http://downloads.sourceforge.net/geoserver/geoserver-2.0.2-war.zip
sudo unzip -d /var/lib/tomcat6/webapps/ geoserver-2.0.2-war.zip
sudo chown -R tomcat6 /var/lib/tomcat6/webapps/geoserver.war
sudo chgrp g+w tomcat6 /var/lib/tomcat6/webapps/geoserver.war

# restart
sudo service tomcat6 restart
sudo service apache2 restart

# echo message
addy=$(GET http://169.254.169.254/latest/meta-data/public-hostname)
echo " "
echo "Geoserver is available at: http://$addy/geoserver"


# additional tweaks for production instances
#
# add the following options to catalina.sh
#
# JAVA_OPTS="-Djava.awt.headless=true -Xms256m -Xmx768m -Xrs -XX:PerfDataSamplingInterval=500 -XX:MaxPermSize=128m -DGEOSERVER_DATA_DIR=/var/lib/tomcat6/webapps/geoserver/data"

