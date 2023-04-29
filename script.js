// gen.sh and append.sh replace DATA with the JSON of a connector
var connectorData = [
/*DATA*/
];

// gen.sh replaces COLS and PRINT_COLS with the apropriate JSON objects
var columns = ///COLS///

var printColumns = ///PRINT_COLS///

// We call this function after creating the main table, and when showing a pin in the info table.
function hideEmptyColumns(table) {
  var rows = table.querySelector("tbody").children;
  var tableHead = table.querySelector("thead>tr");
  var cols = tableHead.children;
  // For every column, loop through all the rows and check if the column is empty
  for (var i = 0; i < cols.length; i++) {
    var empty = true;
    for (var ii = 0; ii < rows.length; ii++) {
      // If we find a row with text, the column isn't empty
      if ( rows[ii].children[i].textContent.length > 0 ) {
        empty = false;
        break;
      }
    }
    // If the column was empty, we have to hide the header,
    //   and also loop through the children and hide them.
    if (empty) {
      tableHead.querySelectorAll("th")[i].style.display = "none";
      for (var ii = 0; ii < rows.length; ii++) {
        rows[ii].children[i].style.display = "none";
      }
    // If not, we do the same procedure, but show instead of hide,
    //   in case they were previously hidden.
    } else {
      tableHead.querySelectorAll("th")[i].style.display = "";
      for (var ii = 0; ii < rows.length; ii++) {
        rows[ii].children[i].style.display = "";
      }
    }
  }
}

// Add a row to a table
function addRow(table, pin) {
  var clone = getRow(table, pin)
  table.appendChild(clone);
}

// Add a row to a table, with an associated connector,
//    so we can scroll the connector into view
function addRow(table, pin, cid, click) {
  click = typeof click !== 'undefined' ? click : true;
  var clone = getRow(table, pin)
  var row = clone.querySelector(".data");
  // If we've been passed a reference to a pin on the connector view,
  //    make this row clickable.
  // This will not be the case:
  //   - When no x/y coordinates were provided for the pin
  //   - When there is no image specified in the input YAML
  if (pin.pdiv && click) {
    row.addEventListener("click", function(table, pin, cid) {
      // Find the closest container up the tree.
      // We don't know how far it is, because the info and
      //   main tables are at different depths.
      var container = table.closest(".container");
      // Handle the click.
      clickPin(container.querySelector(".info-table tbody"), pin, cid);
      // Scroll so the connector view is visible.
      container.scrollIntoView()
    }.bind(null, table, pin, cid));
  }
  table.appendChild(clone);
}

// Build a row to add to a table
function getRow(table, pin) {
  var template = document.getElementById("table-template");
  var clone = template.content.cloneNode(true);
  var row = clone.querySelector(".data");
  // Loop through the columns and create a data element for each
  for (const column in columns) {
    var el = document.createElement("td")
    // If we should print this column (We always print pins)
    if ( printColumns.indexOf(column) !== -1 || column == "pin" ) {
      el.classList.add("print-column");
    }
    // Sometimes the data is an array instead of a string, so we might need to join it.
    el.textContent = Array.isArray(pin[column]) ? pin[column].join(", ") : pin[column];
    el.dataset.field = column
    row.appendChild(el);
  }
  // Set the type of the pin so it will be colored in print view.
  clone.querySelector('[data-field="pin"]').dataset.type = pin.type;
  return clone;
}

// Called when we click on a pin, either in a table or in the connector view
// table is always the info table
function clickPin(table, pin, cid) {
  // Find the closest container up the tree.
  // We don't know how far it is, because table rows and
  //   pins in the connector view are at different depths.
  var container = table.closest(".container");
  // Make sure the table is visible.
  table.parentElement.style.display = "table";
  // Clear the table, then add the row
  table.innerHTML = "";
  addRow(table, pin, cid, false);
  // Loop through the pins, and highlight those of the same type,
  //   remove highlights from any other previously highlighted pins,
  //   and remove selection from all pins.
  var pins = document.querySelectorAll(".pin-marker");
  for (var i = 0; i < pins.length; i++) {
    if (pins[i].dataset.type == pin.type) {
      pins[i].classList.add("highlight");
    } else {
      pins[i].classList.remove("highlight");
    }
    pins[i].classList.remove("selected");
  }
  // Select the clicked pin.
  pin.pdiv.classList.add("selected");
  // Hide empty columns from the table
  hideEmptyColumns(table.parentElement);
  // If there's a connector id for this pin, go to this pin's URL
  if (typeof(cid) != "undefined") {
    var url = new URL(window.location);
    url.searchParams.set("connector", cid);
    url.searchParams.set("pin", pin.pin);
    // Don't ruin the history if we're not going somewhere new.
    if ( url.toString() != new URL(window.location).toString() ) {
      window.history.pushState({}, "", url)
    }
  } else {
    var url = new URL(window.location);
    url.search = "";
    url.searchParams.set("pin", pin.pin);
    // Don't ruin the history if we're not going somewhere new.
    if ( url.toString() != new URL(window.location).toString() ) {
      window.history.pushState({}, "", url)
    }
  }
  container.scrollIntoView()
}

// Check URL parameters for a selected pin
function checkparams() {
  var params = new URLSearchParams(window.location.search);
  var connector = params.get("connector");
  var pin = params.get("pin");
  if (pin == null) {
    return;
  }
  var c;
  // Loop through the connectors and find if there's one that matches.
  for (var i = 0; i < connectorData.length; i++) {
    if (typeof(connectorData[i].info.cid) != "undefined" && connectorData[i].info.cid == connector) {
      c = i;
    } else if (i == connectorData.length - 1){
      c = 0;
    }
  }
  var cdata = connectorData[c];
  var table = document.querySelectorAll(".info-table tbody")[c];
  // Loop through the pins and find if there's one that matches.
  for (var iii = 0; iii < cdata.pins.length; iii++) {
    if (cdata.pins[iii].pin == pin) {
      // Just pretend we clicked on it
      clickPin(table, cdata.pins[iii], cdata.info.cid);
      return;
    }
  }
}

// Keep track of how many images need to be loaded
var images = 0;
// If all images are loaded, check the params for a selected pin.
// We don't want to try to select a pin before the image is loaded.
function checkImagesLoaded() {
  images -= 1;
  if (images == 0) {
    checkparams();
  }
}

// This is a butchery and I hate it and never want to touch it again.
function calcPinSize(pin, cdiv, connector, pinfo) {
  // Find the closest pin, to maximize the pin size for best readability,
  //    without overlapping pins.
  var closest = 1000000;
  for (var ii = 0; ii < connector.info.pins.length; ii++) {
    var tinfo = connector.info.pins[ii];
    var distance = Math.pow((tinfo.x - pinfo.x), 2) + Math.pow((tinfo.y - pinfo.y), 2);
    if (tinfo.pin != pin.pin && (!closest || distance < closest)) {
      closest = distance;
    }
  }
  // Set the pin's size
  closest = Math.sqrt(closest);
  var divheight = cdiv.clientHeight;
  var divwidth = cdiv.clientWidth;
  var mult = cdiv.querySelector("img").naturalHeight / divheight;
  var newheight = (closest / mult)
  var pxheight = divheight * 0.08;
  if (newheight < pxheight) {
    pxheight = newheight;
  }
  var height = (pxheight / divheight) * 100;
  var width = (pxheight / divwidth) * 100;
  pin.pdiv.style.height = "calc(" + height + "%)";
  pin.pdiv.style.width = "calc(" +  width + "%)";
  pin.pdiv.style.lineHeight = "calc(" + pxheight + "px - 0.21vw)";
  pin.pdiv.style.marginTop = "-" + (width / 2) + "%";
  pin.pdiv.style.marginLeft = "-" + (width / 2) + "%";
  pin.pdiv.style.fontSize = (height * 1.8) + "px";
  pin.pdiv.style.fontSize = (pxheight * 0.5) + "px";
  // Recalculate the size for printing.
  window.addEventListener("beforeprint", function(pdiv, width, divwidth, event) {
    pdiv.style.fontSize = "calc(calc(" + width + "px * min(640, "  + divwidth + ")) * 0.0055)";
  }.bind(null, pin.pdiv, width, divwidth));
  window.addEventListener("afterprint", function(pdiv, pxheight, event) {
    pdiv.style.fontSize = (pxheight * 0.5) + "px";
  }.bind(null, pin.pdiv, pxheight));
}

window.addEventListener("load", function() {
  // Manage history navigation
  window.onpopstate = function(ev) {
    if (event.state) {
      checkparams();
    }
  };
  // @ifdef DEBUG
  if (debug) {
    console.log(connectorData.length + " connectors")
  }
  // @endif
  // For every connector...
  for (var c = 0; c < connectorData.length; c++) {
    // Parse the JSON, add connector to document body
    connectorData[c] = JSON.parse(connectorData[c]);
    var connector = connectorData[c];
    var template = document.getElementById("connector-template");
    var clone = template.content.cloneNode(true);
    document.body.appendChild(clone);
    var sdiv = document.body.lastElementChild;
    var img = sdiv.querySelector(".connector-img");
    // When the image is loaded, then handle the pins
    img.addEventListener("load", function(connector, sdiv, img) {
      var cdiv = sdiv.querySelector(".connector-div");
      var cid = connector.info.cid;
      var ptemplate = document.getElementById("pin-template");
      var imgHeight = img.naturalHeight;
      var imgWidth = img.naturalWidth;
      var infoTable = sdiv.querySelector(".info-table").querySelector("tbody");
      var infoTableHeader = sdiv.querySelector(".info-table").querySelector("thead>tr");
      var fullTable = sdiv.querySelector(".pinout-table").querySelector("tbody");
      var fullTableHeader = sdiv.querySelector(".pinout-table").querySelector("thead>tr");
      // Loop through our columns and add the headers for both tables
      for (const column in columns) {
        var el = document.createElement("th");
        el.textContent = columns[column];
        infoTableHeader.appendChild(el.cloneNode(true));
        fullTableHeader.appendChild(el.cloneNode(true));
      }
      // For every pin...
      for (var i = 0; i < connector.pins.length; i++) {
        var pin = connector.pins[i];
        if (!pin.pin) {
          continue;
        }
        // Get the pin info from the info section (i.e. x/y coordinates)
        var pinfo = {};
        for (var ii = 0; ii < connector.info.pins.length; ii++) {
          if (connector.info.pins[ii].pin == pin.pin) {
            pinfo = connector.info.pins[ii];
            break;
          }
        }
        // If there aren't coordinates, just add to the table
        if (!pinfo.x) {
          addRow(fullTable, connector.pins[i], cid);
          continue;
        }
        // Create the pin element and set its position and type
        var pclone = ptemplate.content.cloneNode(true);
        var pdiv = pclone.querySelector("div");
        pdiv.textContent = pinfo.pin;
        pdiv.style.top = ((pinfo.y / imgHeight) * 100) + "%";
        pdiv.style.left = ((pinfo.x / imgWidth) * 100) + "%";
        pdiv.dataset.type = pin.type;
        // Associate the pin's element with the pin object
        pin.pdiv = pdiv;
        pdiv.addEventListener("click", function(table, pin, cid) {
          clickPin(table, pin, cid);
        }.bind(null, infoTable, pin, cid));
        calcPinSize(pin, cdiv, connector, pinfo)
        // Recalculate the size when the window is resized.
        window.addEventListener("resize", function(pin, cdiv, connector, pinfo) {
          calcPinSize(pin, cdiv, connector, pinfo)
        }.bind(null, pin, cdiv, connector, pinfo));
        cdiv.appendChild(pdiv);
        addRow(fullTable, pin, cid);
      }
      hideEmptyColumns(sdiv.querySelector(".pinout-table"));
      // Check if we have loaded all the images.
      checkImagesLoaded();
    }.bind(null, connector, sdiv, img));
    // If there's info, use it.
    if (typeof(connector.info) != "undefined") {
      // Set the document title
      if (document.title.length == 0 && typeof(connector.info.title) != "undefined") {
        document.title = connector.info.title;
      }
      // Add the board link
      if (typeof(connector.info.board_url) != "undefined" && document.title.length > 0) {
        document.getElementById("board-link").innerText = document.title;
        document.getElementById("board-link").href = connector.info.board_url;
      }
      // Add the connector name
      if (typeof(connector.info.name) != "undefined") {
        sdiv.querySelector(".connector-name").innerText = connector.info.name;
      }
    }
    // Add the image to load it
    if (typeof(connector.info) != "undefined" && typeof(connector.info.image) != "undefined") {
      img.src = connector.info.image.file;
      // Increment "images we need to load" counter
      images += 1;
    // If there's no image, just build the table.
    } else {
      img.parentElement.parentElement.style.height = 0;
      var fullTable = sdiv.querySelector(".pinout-table").querySelector("tbody");
      var fullTableHeader = sdiv.querySelector(".pinout-table").querySelector("thead>tr");
      for (var i = 0; i < connector.pins.length; i++) {
        var pin = connector.pins[i];
        if (!pin.pin) {
          continue;
        }
        addRow(fullTable, pin);
      }
      // Loop through our columns and add the headers for the main table
      for (const column in columns) {
        var el = document.createElement("th");
        el.textContent = columns[column];
        fullTableHeader.appendChild(el.cloneNode(true));
      }
      hideEmptyColumns(sdiv.querySelector(".pinout-table"));
    }
  }
});
