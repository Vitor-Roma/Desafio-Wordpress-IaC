#!/bin/bash
sudo apt update && sudo apt install curl ansible unzip -y
cd /tmp
wget https://public-irating-bucket.s3.amazonaws.com/ansible.zip
unzip ansible.zip
cd ansible
sudo ansible-playbook wordpress.yml