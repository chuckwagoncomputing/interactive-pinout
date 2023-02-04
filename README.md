# interactive-pinout
Interactive Pinout Generator

```
- name: Generate Pinouts
  uses: chuckwagoncomputing/interactive-pinout
  with:
    mapping-path: firmware/config/boards/*/connectors
    warnings: skip
    columns: |
      {
      "pin":"Pin Number",
      "ts_name":"TS Name",
      "type":"Type",
      "function":"Typical Function",
      "color":"Pigtail Color"
      }
    print-columns: |
      [
      "function"
      ]
    colors: |
      {
      "5v":"red",
      "5V":"red",
      "at":"green",
      "av":"brown",
      "can":"blue",
      "din":"lime",
      "etb":"darkcyan",
      "gnd":"darkgreen",
      "gp_high":"aqua",
      "gp_low":"aquamarine",
      "gp_pp":"cyan",
      "hall":"darkolivegreen",
      "hl":"gold",
      "hs":"indigo",
      "ign":"magenta",
      "inj":"maroon",
      "mr":"firebrick",
      "pgnd":"coral",
      "sgnd":"olive",
      "usb":"lightseagreen",
      "vr":"sienna"
      }
```
