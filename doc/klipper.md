/dev/ttyS3

## prepare
mkdir -p ~/pip-tmp
set -gx TMPDIR $HOME/pip-tmp

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

## klipper

```
sudo tee /etc/systemd/system/klipper.service >/dev/null <<'EOF'
[Unit]
Description=Klipper 3D Printer Firmware (host)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ksevelyar
Group=ksevelyar
WorkingDirectory=/home/ksevelyar/klipper
ExecStart=/home/ksevelyar/klipper-venv/bin/python /home/ksevelyar/klipper/klippy/klippy.py \
  /home/ksevelyar/printer_data/config/printer.cfg \
  -l /home/ksevelyar/printer_data/logs/klippy.log \
  -a /home/ksevelyar/printer_data/run/klippy.sock
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF
```

sudo systemctl daemon-reload
sudo systemctl enable --now klipper

/usr/local/bin/python3.11 -m venv ~/moonraker-venv
~/moonraker-venv/bin/python -m pip install -U pip setuptools wheel

~/moonraker-venv/bin/pip install -r ~/moonraker/scripts/moonraker-requirements.txt
