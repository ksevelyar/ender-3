# Software

* Raspbian
* OctoPrint
* [Bed Visualizer](https://plugins.octoprint.org/plugins/bedlevelvisualizer/)

## Python

tmux new -s py311

mkdir -p ~/python
cd ~/python

wget -O Python-3.11.8.tar.xz https://www.python.org/ftp/python/3.11.8/Python-3.11.8.tar.xz

tar -xf Python-3.11.8.tar.xz
cd Python-3.11.8

./configure
make -j2
sudo make altinstall

/usr/local/bin/python3.11 --version

## OctoPrint

/usr/local/bin/python3.13 -m venv ~/octoprint/venv
~/octoprint/venv/bin/python -m pip install -U pip setuptools wheel

~/octoprint/venv/bin/python -m pip install -U OctoPrint

 ~/octoprint/venv/bin/python -m pip install -U "git+https://github.com/jneilliii/OctoPrint-BedLevelVisualizer.git"
