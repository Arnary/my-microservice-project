#!/bin/bash

# Debian and Ubuntu

set -ex

if ! command -v docker &> /dev/null; then
	sudo apt update
	sudo apt install -y ca-certificates curl gnupg

	sudo mkdir -p /etc/apt/keyrings && sudo chmod 755 /etc/apt/keyrings

	sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc

	echo \
  	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  	$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  	sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

	sudo apt update

	sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
else 
	echo "Docker has already installed"
fi
 
if ! command -v python3 &> /dev/null; then
	python_version=$(python3 -V 2>&1 | awk '{print $2}')
	if [["$(printf '%s\n' "python_version" "3.9.0" | sort -V | head -n1)" != "3.9.0"]]; then
		sudo apt update
		sudo apt install -y software-properties-common
		sudo add-apt-repository ppa:deadsnakes/ppa
		sudo apt update
		sudo apt install -y python3.12 python3-pip python3-venv
		echo "Python installed successfully"
	fi
else 
	echo "Python has already installed"
fi

if ! command -v pip3 &> /dev/null; then
	sudo apt install -y python3-pip
fi

if ! python3 -m venv --help  &> /dev/null; then
	sudo apt install -y python3-venv
fi

if ! python3 -m django --version &> /dev/null; then
	mkdir ~/newproject
	cd ~/newproject
	python3 -m venv my_env
	source my_env/bin/activate
	pip3 install django
else
	echo "Django has already installed"
fi
