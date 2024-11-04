// npm install --save-dev jest @types/jest
// npm run test

// This is a very funny hack.
var fs = require('fs');
eval((fs.readFileSync('script.js')+'').match(/^function(.|\n)*?^\}/gm).join("\n"));

describe("interpolate pins", () => {

	const pins1 = [
		{
			pin: "K30",
			x: 2340,
			y: 571
		},
		{
			pin: "K31",
			ex: 2413.25,
			ey: 571
		},
		{
			pin: "K32",
			ex: 2486.5,
			ey: 571
		},
		{
			pin: "K33",
			ex: 2559.75,
			ey: 571
		},
		{
			pin: "K34",
			x: 2633,
			y: 571
		}
	];

	const pins2 = [
		{
			pin: "K1-11",
			x: 2340,
			y: 571
		},
		{
			pin: "K1-12",
			ex: 2413.25,
			ey: 571
		},
		{
			pin: "K1-13",
			ex: 2486.5,
			ey: 571
		},
		{
			pin: "K1-14",
			ex: 2559.75,
			ey: 571
		},
		{
			pin: "K1-15",
			x: 2633,
			y: 571
		}
	];

	const sets = [pins1, pins2];
	sets.forEach(pins => {
		var p1 = pins[0]
		var p2 = pins.at(-1)
		pins.slice(1, -1).forEach((pin, i) => {
			test(`${pin.pin} findBounds test`, () => {
				expect(findBounds(pins, i+1)).toEqual([p1, p2])
			});
			test(`${pin.pin} findBetween test`, () => {
				expect(findBetween(p1, p2, pin)).toEqual({x: pin.ex, y: pin.ey})
			});
		});
	});
});
