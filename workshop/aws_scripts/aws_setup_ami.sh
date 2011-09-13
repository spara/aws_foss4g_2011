# setup sources 
sudo sh -c "echo ' ' >> /etc/apt/sources.list"
sudo sh -c "echo 'deb http://us.archive.ubuntu.com/ubuntu/ lucid multiverse' >> /etc/apt/sources.list"
sudo sh -c "echo 'deb-src http://us.archive.ubuntu.com/ubuntu/ lucid multiverse' >> /etc/apt/sources.list"
sudo sh -c "echo 'deb http://us.archive.ubuntu.com/ubuntu/ lucid-updates multiverse' >> /etc/apt/sources.list"
sudo sh -c "echo 'deb-src http://us.archive.ubuntu.com/ubuntu/ lucid-updates multiverse' >> /etc/apt/sources.list"
sudo sh -c "echo 'deb http://archive.canonical.com/ lucid partner' >> /etc/apt/sources.list"
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

sudo apt-get -y install ec2-api-tools
sudo apt-get -y install ec2-ami-tools

cd ~/
wget http://ec2-downloads.s3.amazonaws.com/AutoScaling-2011-01-01.zip
unzip AutoScaling-2011-01-01.zip -d autoscaling

wget http://ec2-downloads.s3.amazonaws.com/CloudWatch-2010-08-01.zip
unzip CloudWatch-2010-08-01.zip -d cloudwatch

touch ~/.bash_profile
sh -c "echo 'export AWS_AUTO_SCALING_HOME=/home/ubuntu/autoscaling/AutoScaling-1.0.39.0' >> ~/.bash_profile"
sh -c "echo 'export PATH=$PATH:$AWS_AUTO_SCALING_HOME/bin' >> ~/.bash_profile"
sh -c "echo 'export AWS_CLOUDWATCH_HOME=/home/ubuntu/cloudwatch/CloudWatch-1.0.12.1' >> ~/.bash_profile"
sh -c "echo 'export PATH=$PATH:$AWS_CLOUDWATCH_HOME/bin' >> ~/.bash_profile"
source .bash_profile

as-create-launch-config foss4g --image-id ami-e975b680 \
  --instance-type t1.micro \
  --group default \
  -K ~/keys/pk-LEDMQAI6WR2YZLNYCCJMKZXP2LSW7VBG.pem \
  -C ~/keys/cert-LEDMQAI6WR2YZLNYCCJMKZXP2LSW7VBG.pem

as-create-auto-scaling-group foss4ggroup \
  --launch-configuration foss4g \
  --availability-zones us-east-1a \
  --min-size 3 \
  --max-size 10 \
  --load-balancers foss4gLoadBalancer \
  -K ~/keys/pk-LEDMQAI6WR2YZLNYCCJMKZXP2LSW7VBG.pem \
  -C ~/keys/cert-LEDMQAI6WR2YZLNYCCJMKZXP2LSW7VBG.pem




