echo "Hello fro installer script"

# Step2: install osconfig
sudo sh -c "echo 'deb http://packages.cloud.google.com/apt google-osconfig-agent-stable main' >> /etc/apt/sources.list"
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
sudo apt-get update
sudo apt-get install -y google-osconfig-agent
