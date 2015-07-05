sed -i 's/git@github.com:/https:\/\/github.com\//' .gitmodules

git submodule update --init --recursive

#sudo apt-get update -qq

#sudo apt-get install -y g++-multilib

wget -qO- https://deb.nodesource.com/setup_0.12 | sudo bash -

sudo apt-get install -y nodejs