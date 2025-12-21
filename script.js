// gen.sh and append.sh replace DATA with the JSON of a connector
var connectorData = [
/*DATA*/
];

// gen.sh replaces COLS with a JSON object
const globalColumns = ///COLS///;

// gen.sh replaces PRINT_COLS with a JSON array
const globalPrintColumns = ///PRINT_COLS///;

// gen.sh replaces INFO_COL with a string
const globalInfoColumn = "///INFO_COL///";

// gen.sh replaces TEMPLATES with a JSON object
const templates = ///TEMPLATES///;

// We call this function after creating the main table, and when showing a pin in the info table.
function hideEmptyColumns(table) {
	const rows = Array.from(table.querySelector("tbody").children);
	const tableHeads = Array.from(table.querySelector("thead>tr").children);
	// For every column, loop through all the rows and check if the column is empty
	tableHeads.forEach((col, i) => {
		const found = rows.find((r) => r.children[i] && r.children[i].textContent.length > 0);
		// If the column was empty, we have to hide the header and the children,
		// If not, we do the same procedure, but show instead of hide.
		col.style.display = found ? "" : "none";
		rows.forEach((r) => {
			if (r.children[i]) {
				r.children[i].style.display = found ? "" : "none";
			}
		});
	});
}

// Add a row to a table, with an associated connector,
//		so we can scroll the connector into view
function addRow(table, pin, c, click) {
	click = typeof click !== 'undefined' ? click : true;
	const clone = getRow(pin, connectorData[c]);
	const row = clone.querySelector(".data");
	// If we've been passed a reference to a pin on the connector view,
	//		make this row clickable.
	// This will not be the case:
	//	 - When no x/y coordinates were provided for the pin and couldn't be interpolated
	//	 - When there is no image specified in the input YAML
	if (pin.pdiv && click) {
		row.addEventListener("click", () => {
			// Find the closest container up the tree.
			// We don't know how far it is, because the info and
			//	 main tables are at different depths.
			const container = table.closest(".container");
			// Handle the click.
			clickPin(container.querySelector(".info-table tbody"), pin, c);
			// Scroll so the connector view is visible.
			container.scrollIntoView();
		});
	}
	table.appendChild(clone);
}

// Build a row to add to a table
function getRow(pin, connector) {
	const template = document.getElementById("table-template");
	const clone = template.content.cloneNode(true);
	const row = clone.querySelector(".data");
	// Loop through the columns and create a data element for each
	const columns = (connector && connector.info.columns) || globalColumns;
	for (const column in columns) {
		const el = document.createElement("td")
		// If we should print this column (We always print pins)
		const printColumns = (connector && connector.info["print-columns"]) || globalPrintColumns;
		if ( printColumns.indexOf(column) !== -1 || column == "pin" ) {
			el.classList.add("print-column");
		}
		// Sometimes the data is an array instead of a string, so we might need to join it.
		let text = Array.isArray(pin[column]) ? pin[column].join(", ") : pin[column];
		if (typeof templates === "object" && typeof text === "string") {
			for (const template in templates) {
				text = text.replace(template, pin[templates[template]])
			}
		}
		el.textContent = text;
		el.dataset.field = column;
		row.appendChild(el);
	}
	// Set the type of the pin so it will be colored in print view.
	clone.querySelector('[data-field="pin"]').dataset.type = pin.type;
	if (pin.color) {
		clone.querySelector('[data-field="pin"]').dataset.color = pin.color;
	}
	return clone;
}

// Called when we click on a pin, either in a table or in the connector view
// table is always the info table
function clickPin(table, pin, c) {
	// Find the closest container up the tree.
	// We don't know how far it is, because table rows and
	//	 pins in the connector view are at different depths.
	const container = table.closest(".container");
	// Make sure the table is visible.
	table.parentElement.style.display = "table";
	// Clear the table, then add the row
	table.innerHTML = "";
	addRow(table, pin, c, false);
	highlightType(pin.type)
	// Select the clicked pin.
	pin.pdiv.classList.add("selected");
	// Hide empty columns from the table
	hideEmptyColumns(table.parentElement);
	// If there's a connector id for this pin, go to this pin's URL
	if (typeof(c) != "undefined") {
		const url = new URL(window.location);
		url.searchParams.set("connector", connectorData[c].info.cid);
		url.searchParams.set("pin", pin.pin);
		url.searchParams.delete("type");
		// Don't ruin the history if we're not going somewhere new.
		if ( url.toString() != new URL(window.location).toString() ) {
			window.history.pushState({}, "", url)
		}
	} else {
		const url = new URL(window.location);
		url.search = "";
		url.searchParams.set("pin", pin.pin);
		url.searchParams.delete("type");
		// Don't ruin the history if we're not going somewhere new.
		if ( url.toString() != new URL(window.location).toString() ) {
			window.history.pushState({}, "", url)
		}
	}
	container.scrollIntoView();
}

function highlightType(type) {
	// Loop through the pins, and highlight those of the same type,
	//	 remove highlights from any other previously highlighted pins,
	//	 and remove selection from all pins.
	document.querySelectorAll(".pin-marker").forEach((pin) => {
		if (pin.dataset.type == type) {
			pin.classList.add("highlight");
		} else {
			pin.classList.remove("highlight");
		}
		pin.classList.remove("selected");
	});
}

function addTypeToTable(type) {
	// Add pins matching type to their connector table
	let found = false;
	connectorData.forEach((cdata, i) => {
		const table = document.querySelectorAll(".info-table tbody")[i];
		cdata.pins.forEach((pin) => {
			if (pin.type == type) {
				if (!found) {
					// scroll to the connector of the first found matching pin
					table.closest(".container").scrollIntoView();
					found = true;
				}
				table.parentElement.style.display = "table";
				addRow(table, pin, i);
			}
		});
	});
}

// Check URL parameters for a selected pin
function checkparams() {
	const params = new URLSearchParams(window.location.search);
	const type = params.get("type");
	if (type != null) {
		highlightType(type);
		addTypeToTable(type);
		return;
	}
	const connector = params.get("connector");
	const pin = params.get("pin");
	if (pin == null) {
		return;
	}

	// Loop through the connectors and find if there's one that matches.
	let c =	connectorData.findIndex((data) => (typeof(data.info.cid) != "undefined" && data.info.cid == connector)) || 0;
	const cdata = connectorData[c];
	const table = document.querySelectorAll(".info-table tbody")[c];
	// Loop through the pins and find if there's one that matches.
	cdata.pins.forEach((cpin) => {
		if (cpin.pin == pin) {
			// Just pretend we clicked on it
			clickPin(table, cpin, c);
			return;
		}
	});
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
	//		without overlapping pins.
	let closest = 1000000;
	connector.info.image.pins.forEach((tinfo) => {
		if (tinfo.pin == pin.pin) return;
		const distance = Math.pow((tinfo.x - pinfo.x), 2) + Math.pow((tinfo.y - pinfo.y), 2);
		if (distance < closest) {
			closest = distance;
		}
	});
	closest = Math.sqrt(closest);
	// Set the pin's size
	const divheight = cdiv.clientHeight;
	const divwidth = cdiv.clientWidth;
	const scale = divheight / cdiv.querySelector("img").naturalHeight;
	const newheight = closest * scale;
	// Default height is 8% of div
	let pinsize = divheight * 0.08;
	if (newheight < pinsize) {
		pinsize = newheight;
	}
	// Use percent for scaling when printing
	const height = (pinsize / divheight) * 100;
	const width = (pinsize / divwidth) * 100;
	pin.pdiv.style.height = height + "%";
	pin.pdiv.style.width = width + "%";
	// 0.5cqh achieves vertical centering, roughly
	pin.pdiv.style.lineHeight = (height - 0.5) + "cqh";
	// When using a percent for margins, the width value is used even for top and bottom
	pin.pdiv.style.marginTop = "-" + (width / 2) + "%";
	pin.pdiv.style.marginLeft = "-" + (width / 2) + "%";
	pin.pdiv.style.fontSize = (height * 0.5) + "cqh";
}

function findBounds(pins, i) {
	let d = i;
	let u = i;
	for (; d > -1; d--) {
		if (typeof(pins[d].x) != "undefined" && typeof(pins[d].y) != "undefined") {
			break;
		}
	}
	for (; u < pins.length; u++) {
		if (typeof(pins[u].x) != "undefined" && typeof(pins[u].y) != "undefined") {
			break;
		}
	}
	return [pins[d], pins[u]]
}

function findBetween(a, b, p) {
	const a_ns = ("" + a.pin).match(/\d+/g)
	const b_ns = ("" + b.pin).match(/\d+/g)
	const n_ns = ("" + p.pin).match(/\d+/g)
	let n = 0;
	for (let i = 0; i < a_ns.length; i++) {
		if (a_ns[i] != b_ns[i]) {
			a.n = a_ns[i];
			b.n = b_ns[i];
			n = n_ns[i];
			break
		}
	}
	return brange(a, b, n);
}

function range(x1, x2, n1, n2, n) {
	n1 = parseInt(n1);
	n2 = parseInt(n2);
	x1 = parseInt(x1);
	x2 = parseInt(x2);
	n = parseInt(n);
	return x1 + (x2 - x1) * ((n - n1) / (n2 - n1));
}

function brange(p1, p2, n) {
	return {
		x: range(p1.x, p2.x, p1.n, p2.n, n),
		y: range(p1.y, p2.y, p1.n, p2.n, n)
	};
}

function setupColorToggle(sdiv, columns) {
	const colored = sdiv.querySelectorAll("[data-color]")
	if (colored.length > 0) {
		sdiv.querySelector(".switch-block").style.display = "block"
		sdiv.querySelector(".toggle-label").style.display = "block"
		const ctog = sdiv.querySelector(".color-toggle");
		ctog.addEventListener("change", (e) => {
			sdiv.querySelectorAll("[data-color]").forEach((pin) => {
				if (e.target.checked) {
					pin.style.borderColor = pin.dataset.color.replace(/\s/g, "");
				} else {
					pin.style.borderColor = ""
				}
			});
		});
	}
	if (typeof(columns["color"]) != "undefined") {
		sdiv.querySelector(".color-label").innerText = columns["color"]
	}
}

function handleImageLoad(connector, c, sdiv, img, columns) {
	const cdiv = sdiv.querySelector(".connector-div");
	const cdc = sdiv.querySelector(".connector-div-container");
	cdc.style.aspectRatio = img.naturalWidth / img.naturalHeight;
	const ptemplate = document.getElementById("pin-template");
	const pitemplate = document.getElementById("pin-info-template");
	const imgHeight = img.naturalHeight;
	const imgWidth = img.naturalWidth;
	const infoTable = sdiv.querySelector(".info-table").querySelector("tbody");
	const infoTableHeader = sdiv.querySelector(".info-table").querySelector("thead>tr");
	const fullTable = sdiv.querySelector(".pinout-table").querySelector("tbody");
	const fullTableHeader = sdiv.querySelector(".pinout-table").querySelector("thead>tr");
	// Loop through our columns and add the headers for both tables
	for (const column in columns) {
		const el = document.createElement("th");
		el.textContent = columns[column];
		infoTableHeader.appendChild(el.cloneNode(true));
		fullTableHeader.appendChild(el.cloneNode(true));
	}
	// For every pin...
	connector.pins.forEach((pin) => {
		if (!pin.pin) {
			return;
		}
		// Get the pin info from the info section (i.e. x/y coordinates)
		const pinfoidx = connector.info.image.pins.findIndex((e) => e.pin == pin.pin);
		const pinfo = connector.info.image.pins[pinfoidx];
		// If we found a listing without coordinates
		if (pinfo && !pinfo.x) {
			const bounds = findBounds(connector.info.image.pins, pinfoidx)
			if (typeof(bounds[0]) != "undefined" && typeof(bounds[1]) != "undefined") {
				Object.assign(pinfo, findBetween(bounds[0], bounds[1], pinfo))
			}
		}
		// If we didn't find a listing in the image section, just add to the table
		if (!pinfo || !pinfo.x) {
			addRow(fullTable, pin, c);
			return;
		}
		// Create the pin element and set its position and type
		const pclone = ptemplate.content.cloneNode(true);
		const pdiv = pclone.querySelector("div");
		pdiv.textContent = pinfo.pin;
		const piclone = pitemplate.content.cloneNode(true);
		const pidiv = piclone.querySelector(".pin-info");
		pidiv.textContent = pin[connector.info["info-column"] || globalInfoColumn];
		pdiv.appendChild(piclone);
		pdiv.style.top = ((pinfo.y / imgHeight) * 100) + "%";
		pdiv.style.left = ((pinfo.x / imgWidth) * 100) + "%";
		pdiv.dataset.type = pin.type;
		if (pin.color) {
			pdiv.dataset.color = pin.color;
		}
		// Associate the pin's element with the pin object
		pin.pdiv = pdiv;
		pdiv.addEventListener("click", () => {
			clickPin(infoTable, pin, c);
		});
		calcPinSize(pin, cdiv, connector, pinfo)
		// Recalculate the size when the window is resized.
		resizeHandlers.push(() => {
			calcPinSize(pin, cdiv, connector, pinfo)
		});
		cdiv.appendChild(pdiv);
		addRow(fullTable, pin, c);
	});
	hideEmptyColumns(sdiv.querySelector(".pinout-table"));
	setupColorToggle(sdiv, columns);
	// Check if we have loaded all the images.
	checkImagesLoaded();
}

function buildConnector(connector, c) {
	const columns = (connector && connector.info.columns) || globalColumns;
	const template = document.getElementById("connector-template");
	const clone = template.content.cloneNode(true);
	document.body.appendChild(clone);
	const sdiv = document.body.lastElementChild;
	const img = sdiv.querySelector(".connector-img");
	// When the image is loaded, then handle the pins
	img.addEventListener("load", () => handleImageLoad(connector, c, sdiv, img, columns));
	// If there's info, use it.
	if (typeof(connector.info) != "undefined") {
		// Set the document title
		if (document.title.length == 0 && typeof(connector.info.title) != "undefined") {
			document.title = connector.info.title;
		}
		// bacwards compatability
		if (typeof(connector.info.board_url) != "undefined") {
			connector.info["board-url"] = connector.info.board_url;
		}
		// Add the board link
		if (typeof(connector.info["board-url"]) != "undefined" && document.title.length > 0) {
			document.getElementById("board-link").innerText = document.title;
			document.getElementById("board-link").href = connector.info["board-url"];
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
		const fullTable = sdiv.querySelector(".pinout-table").querySelector("tbody");
		const fullTableHeader = sdiv.querySelector(".pinout-table").querySelector("thead>tr");
		connector.pins.forEach((pin) => {
			if (!pin.pin) {
				return;
			}
			addRow(fullTable, pin, c);
		});
		// Loop through our columns and add the headers for the main table
		for (const column in columns) {
			const el = document.createElement("th");
			el.textContent = columns[column];
			fullTableHeader.appendChild(el.cloneNode(true));
		}
		hideEmptyColumns(sdiv.querySelector(".pinout-table"));
		setupColorToggle(sdiv, columns);
	}
}

let resizeHandlers = [];

window.addEventListener("load", function() {
	// Manage history navigation
	window.onpopstate = () => {
		checkparams();
	};
	// @ifdef DEBUG
	if (debug) {
		console.log(connectorData.length + " connectors")
	}
	// @endif

	// Parse JSON strings
	for (let c = 0; c < connectorData.length; c++) {
		// Parse the JSON, add connector to document body
		connectorData[c] = JSON.parse(connectorData[c]);
		const connector = connectorData[c];
		if (connector && connector.info) {
			if (connector.info.columns) {
				connector.info.columns = JSON.parse(connector.info.columns);
			}
			if (connector.info["print-columns"]) {
				connector.info["print-columns"] = JSON.parse(connector.info["print-columns"]);
			}
		}
	}

	connectorData.forEach(buildConnector);

	// Recalculate pin sizes when the window is resized.
	window.addEventListener("resize", () => {
		beforePrintHandlers = [];
		afterPrintHandlers = [];
		resizeHandlers.forEach((h) => h());
	});
});
