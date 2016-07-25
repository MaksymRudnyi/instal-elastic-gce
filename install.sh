#!/bin/bash

ES_CLUSTERNAME="cluster-name"

echo -e "\n"
echo "First do some housekeeping"
echo -e "\n"
apt-get update
apt-get -y upgrade
apt-get -y --force-yes install  apt-transport-https

echo -e "\n"
echo "Adding Java repositories"
echo -e "\n"

echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886

echo -e "\n"
echo "Adding ElasticSearch repositories"
echo -e "\n"

wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://packages.elastic.co/elasticsearch/2.x/debian stable main" | tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list

echo -e "\n"
echo "Adding Kibana repositories"
echo -e "\n"

wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb http://packages.elastic.co/kibana/4.5/debian stable main" | sudo tee -a /etc/apt/sources.list

echo -e "\n"
echo "Update repositories"
echo -e "\n"

apt-get update

#Install Java
echo -e "\n"
echo "Installing Java8"
echo -e "\n"

export DEBIAN_FRONTEND="noninteractive"
echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 boolean true" | debconf-set-selections -v
apt-get -y install oracle-java8-installer


echo -e "\n"
echo "Installing elasticsearch-2.x"
echo -e "\n"

apt-get -y install elasticsearch
echo -e "\n"
echo "Installing kibana"
echo -e "\n"

apt-get -y install kibana

echo -e "\n"
echo "Installing marvel-agent and cloud-gce plugins for elasticsearch"
echo -e "\n"

cd /usr/share/elasticsearch/bin
./plugin install -b license
./plugin install -b marvel-agent
./plugin install -b cloud-gce

echo -e "\n"
echo "Installing elastic head plugin"
echo -e "\n"

cd /usr/share/elasticsearch/bin
./plugin install mobz/elasticsearch-head

echo -e "n"
echo "Installing marvel into kibana"
echo -e "\n"

cd /opt
chown -R kibana. kibana
cd /opt/kibana/bin
./kibana plugin --install elasticsearch/marvel/latest

echo -e "\n"
echo "Installing sence into kibana"
echo -e "\n"

cd /opt/kibana/bin
./kibana plugin --install elastic/sense


#install logstash
cd /opt/kibana
echo 'deb http://packages.elastic.co/logstash/2.3/debian stable main' | sudo tee /etc/apt/sources.list.d/logstash-2.3.x.list
sudo apt-get update
sudo apt-get install logstash


echo -e "\n"
echo "Configuring elasticsearch"
echo -e "\n"

sed -i "s/^#\ cluster.name.*/cluster.name:\ $ES_CLUSTERNAME/g" /etc/elasticsearch/elasticsearch.yml
sed -i 's/^#\ network.host.*/network.host:\ 0.0.0.0/g' /etc/elasticsearch/elasticsearch.yml
sed -i 's/^#\ http.port:.*/http.port:\ 9200/g' /etc/elasticsearch/elasticsearch.yml
sed -i 's/^#\ gateway.*/gateway.recover_after_nodes:\ 2/g' /etc/elasticsearch/elasticsearch.yml
sed -i "s/^#\ discovery.zen.minimum_master_nodes.*/discovery.zen.minimum_master_nodes:\ 2/g" /etc/elasticsearch/elasticsearch.yml

cat >> /etc/elasticsearch/elasticsearch.yml << eof

cloud:
  gce:
    project_id: [PROJECT_ID]
    zone: us-central1-a #any zone
discovery:
  type: gce
eof

echo -e "\n"
echo "Configure the kibana"
echo -e '\n'
a
sed -i 's/^#\ server.port/server.port/g' /opt/kibana/config/kibana.yml
sed -i 's/^# server.host/server.host/g' /opt/kibana/config/kibana.yml
sed -i 's/^#\ elasticsearch.url/elasticsearch.url/g' /opt/kibana/config/kibana.yml
sed -i 's/^#\ kibana.index/kibana.index/g' /opt/kibana/config/kibana.yml
chown -R kibana. /opt/kibana

echo -e "\n"
echo "Starting up elasticsearch and kibana services"
echo -e "n"

update-rc.d elasticsearch defaults
update-rc.d kibana defaults
service elasticsearch restart
service kibana restart

sudo apt-get install -y mc