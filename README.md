# Interactive Pinout Generator

Generating pinouts requires:

- ECU connector photo (.jpg)
- pinout metadata file in [YAML](https://en.wikipedia.org/wiki/YAML) format

## Syntax of Connector YAML

Each YAML file contains two sections: 'pins' and 'info'

The 'pins' section contains a list of pins, each having the following fields:  

|field   |description|
|--------|-----------|
|pin     |a numeric id corresponding to the physical pin on the connector|
|type    |a short code to allow pins to be grouped and colored by type|

The 'info' section contains information which is used to generate the interactive pinout. It contains the following fields:  

|field    |description|
|---------|-----------|
|id       |contains a short name for the connector, to be used in the URL when linking to a particular pin|
|image    |subsection which contains a single field, 'file', which contains the filename of the image, which is stored in the same directory as the YAML|
|pins     |subsection with a list of the pins' locations on the image. Its fields are 'pin', which matches to an 'id' in the main 'pins' section, 'x' and 'y', which are the coordinates on the image|
|title    |contains the title for the page. Only one connector for a particular board needs this field|
|board_url|contains a URL for documentation, which will be placed as a link on the top of the page. Only one connector for a particular board needs this field|
|name     |contains a human-readable name for the connector|
|order    |contains an index to order the connectors on the page. The lower the number, the nearer the top of the page. If the 'order' field is not present, order is undefined, but will probably be sorted alphabetically by the file name|

## Using this Action in Your Workflow

Here is an example workflow step:

```
- name: Generate Pinouts
  uses: chuckwagoncomputing/interactive-pinout
  with:
    mapping-path: ./firmware/config/boards/*/connectors
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
      "12v":"yellow";
      "12V":"yellow";
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
      "ls":"lightgreen",
      "mr":"firebrick",
      "pgnd":"coral",
      "sgnd":"olive",
      "usb":"lightseagreen",
      "vr":"sienna"
      }
```
