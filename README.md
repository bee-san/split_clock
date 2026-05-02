# Split Clock

## Install (quick)

```bash
git clone https://github.com/bee-san/split_clock.git
cd split_clock
kpackagetool6 -t Plasma/Applet -u .
systemctl --user restart plasma-plasmashell.service
```

If you already have the source somewhere else, skip clone and run:

```bash
kpackagetool6 -t Plasma/Applet -u /path/to/split_clock
```
