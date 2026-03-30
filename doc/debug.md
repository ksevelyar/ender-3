# Debug

## Device Tree
```
dtc -I dtb -O dts /boot/nixos/5v6534ipxg4rh39p1ip11rgxrg25dkvf-device-tree-overlays/sun8i-h2-plus-bananapi-m2-zero.dtb > current.dts
```

## Serial
```
cat /proc/device-tree/soc/serial@1c28c00/status

okay
```

```
stty -F /dev/ttyS3 -a

speed 0 baud; rows 0; columns 0; line = 0;
intr = ^C; quit = ^\; erase = ^?; kill = ^U; eof = ^D; eol = <undef>; eol2 = <undef>; swtch = <undef>; start = ^Q; stop = ^S; susp = ^Z; rprnt = ^R; werase = ^W; lnext = ^V; discard = ^O; min = 0; time = 0;
-parenb -parodd -cmspar cs8 -hupcl -cstopb cread clocal -crtscts
-ignbrk -brkint -ignpar -parmrk -inpck -istrip -inlcr -igncr -icrnl -ixon -ixoff -iuclc -ixany -imaxbel -iutf8
-opost -olcuc -ocrnl -onlcr -onocr -onlret -ofill -ofdel nl0 cr0 tab0 bs0 vt0 ff0
-isig -icanon -iexten -echo -echoe -echok -echonl -noflsh -xcase -tostop -echoprt -echoctl -echoke -flusho -extproc
```
