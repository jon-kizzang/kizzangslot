/*
	Testing for the Undersea World 2 game
*/

/** Package requirements **/
var fs = require('fs');
var should = require('should');
var xml2js = require('xml2js');

/** Custom package requirements **/
var common = require('../include/common');
var SlotSession = require('../classes/data/SlotSession').SlotSession;

/** Slot games **/
var UnderseaWorld2Game = require("../classes/games/UnderseaWorld2Game").UnderseaWorld2Game;

/** Settings Variables **/
var numberOfBonus = 100;
var numberOfSpins = 1000;
var totalSeconds = 300;
var totalSpins = 35;
var fsMaxSpins = 30;
var xmlFileName = "./xml/math/underseaworld2.xml";

/** Global Variables **/
var game = null;
var parser = new xml2js.Parser({trim:true});
var xmlString = null;
var xmlData = null;

/** Test Code **/

// "main" testing function
function run(){

	describe("UnderseaWorld2", function(){

		findXML();
		parseXML();
		loadGame();
		singleSpin(); // Start by doing a single spin
		fullGame();
		expandingTiles();
		bonusGame();
		bonusTime();
	});
}

// Find the XML for this game
function findXML(){
	describe("Find XML", function(){
		it("Game XML titled 'underseaworld2.xml' should be found in './xml/math'", function(done){

			fs.readFile(xmlFileName, function(err, data){

				if (err) throw err;

				xmlString = data; 

				done();
			});
		});
	});
}

// Parse the xml for this game
function parseXML(){
	describe("Parse XML", function(){
		it("Game XML should parse without errors", function(done){

			parser.parseString(xmlString, function(err, result){

				if (err) throw err;

				xmlData = result.math;

				done();
			});
		});
	});
}

// Load the game
function loadGame(){
	describe("Load Game", function(){
		it ("Game XML should contain the id 'underseaworld2'", function(){

			xmlData.$.id.should.equal("underseaworld2");
		});

		it ("Game should initialize without errors", function(){

			game = new UnderseaWorld2Game();
		});

		it ("Game should import XML settings without errors", function(){

			game.importGame(xmlData);
		});
	})
}

// Do a single, initial, spin
function singleSpin(){
	describe("Single Spin", function(){

		var state = null
		var spinData = null;

		it ("Game should create an initial state without errors", function(){

			state = game.createState(totalSpins, totalSeconds);
		})

		it ("Game should spin without any errors", function(){

			spinData = game.spin(state);
		})

		it ("Spin payout should be within bounds set in xml", function(){

			spinData.spin.wins.pay.should.be.within(xmlData.minSingleSpinAmount, xmlData.maxSingleSpinAmount);
		});

		// In the case of a single spin, there should always just be one less spin remaining than the total
		it ("Spins remaining should have decremented properly", function(){

			spinData.state.spinsLeft.should.equal(totalSpins - 1);
		})
	});
}

// Spin until we run out of spins
function fullGame(){
	describe("Full Game", function(){

		var spinState = null;
		var bonusSpins = 0;

		// Spin until we run out of spins
		it ("Should be able to run a full game without errors", function(){

			// Timeout after 0.5 seconds
			this.timeout(500);

			var spinData = null;
			var spinState = game.createState(totalSpins, totalSeconds);
			
			//console.log(spinState);
			spinsRemaining = totalSpins;

			while (spinsRemaining > 0)
			{
				var prevFreeSpins = spinState.fsSpinsTotal;
				spinData = game.spin(spinState);
				spinState = spinData.state;
				spinsRemaining = spinState.spinsLeft;
				
				//console.log("Spins: " + spinState.spinsLeft + " | Free spins: " + spinState.fsSpinsLeft);
				if (prevFreeSpins < spinState.fsSpinsTotal) { 
					bonusSpins += (spinState.fsSpinsTotal - prevFreeSpins);
					//console.log(spinState);
					//console.log("Prev: " + prevFreeSpins + " | New: " + spinState.fsSpinsTotal + "| Remaining: " + spinState.fsSpinsLeft + " | " + bonusSpins);
				}
			}
		});
	});
}

// Spin to verify each expanding tile
function expandingTiles(){
	describe("Expanding Tiles", function(){

		// in this test we don't care about previous state as it doesn't play a part in this feature
		var P1Fail = false;
		var P2Fail = false;
		var P3Fail = false;
		var WFail = false;

		// Verify that the xml data actually has all of the expanding tokens in the central reel
		describe("XML Verification", function(){
			it ("The center reel should contain the 'P1' symbol", function(){

				if(xmlData.stripGroup[0].strip[2].$.symbols.indexOf("P1") == -1){

					P1Fail = true;
					throw new Error("'P1' not found in the center reel!");
				}
			});

			it ("The center reel should contain the 'P2' symbol", function(){

				if(xmlData.stripGroup[0].strip[2].$.symbols.indexOf("P2") == -1){

					P2Fail = true;
					throw new Error("'P2' not found in the center reel!");
				}
			});

			it ("The center reel should contain the 'P3' symbol", function(){

				if(xmlData.stripGroup[0].strip[2].$.symbols.indexOf("P3") == -1){

					P3Fail = true;
					throw new Error("'P3' not found in the center reel!");
				}
			});

			it ("The center reel should contain the 'W' symbol", function(){

				if(xmlData.stripGroup[0].strip[2].$.symbols.indexOf("W") == -1){

					WFail = true;
					throw new Error("'W' not found in the center reel!");
				}
			});
		});

		describe("Expansion", function(){
			it ("Should see P1 expand to fill the 2nd, 3rd, and 4th rows with M1", function(){
				
				if (P1Fail) 
					throw new Error("P1 does not exist on the center reel!");
				else
				{	
					var hitFound = false;
					for (var i=0; i<numberOfSpins; i++)
					{
						var state = game.spin(game.createState(totalSpins, totalSeconds));

						if(state.spin.window[2][1] == "M1")
						{
							hitFound = true;

							for (var j=1; j<=3; j++)
							{
								for (var k=0; k<3; k++)
								{
									state.spin.window[j][k].should.equal("M1");
								}
							}

							break;
						}
					}

					if (!hitFound) throw new Error("P1 not drawn after " + numberOfSpins + " spins!");
				}
			});

			it ("Should see P2 expand to fill the 2nd, 3rd, and 4th rows with M2", function(){
				
				if (P2Fail) 
					throw new Error("P2 does not exist on the center reel!");
				else
				{	
					var hitFound = false;
					for (var i=0; i<numberOfSpins; i++)
					{
						var state = game.spin(game.createState(totalSpins, totalSeconds));

						if(state.spin.window[2][1] == "M2")
						{
							hitFound = true;

							for (var j=1; j<=3; j++)
							{
								for (var k=0; k<3; k++)
								{
									state.spin.window[j][k].should.equal("M2");
								}
							}

							break;
						}
					}

					if (!hitFound) throw new Error("P2 not drawn after " + numberOfSpins + " spins!");
				}
			});

			it ("Should see P3 expand to fill the 2nd, 3rd, and 4th rows with M3", function(){
				
				if (P3Fail) 
					throw new Error("P3 does not exist on the center reel!");
				else
				{	
					var hitFound = false;
					for (var i=0; i<numberOfSpins; i++)
					{
						var state = game.spin(game.createState(totalSpins, totalSeconds));

						if(state.spin.window[2][1] == "M3")
						{
							hitFound = true;

							for (var j=1; j<=3; j++)
							{
								for (var k=0; k<3; k++)
								{
									state.spin.window[j][k].should.equal("M3");
								}
							}

							break;
						}
					}

					if (!hitFound) throw new Error("P3 not drawn after " + numberOfSpins + " spins!");
				}
			});

			it ("Should see W expand to fill the 3rd row", function(){
				
				if (WFail) 
					throw new Error("W does not exist on the center reel!");
				else
				{	
					var hitFound = false;
					for (var i=0; i<numberOfSpins; i++)
					{
						var state = game.spin(game.createState(totalSpins, totalSeconds));

						if(state.spin.window[2][1] == "W")
						{
							hitFound = true;

							for (var j=0; j<3; j++)
							{
								state.spin.window[2][j].should.equal("W");
							}

							break;
						}
					}

					if (!hitFound) throw new Error("W not drawn after " + numberOfSpins + " spins!");
				}
			});
		});
	});
}

// Test the requirements of the bonus game
function bonusGame(){
	describe("Bonus Game", function(){
		describe("XML Verification", function(){
			it("Math XML should contain 12 elements in the 'wheelWedges' field", function(){

				xmlData.wheelWedges[0].split(',').length.should.equal(12);
			});

			it("Math XML should contain 10 elements in the 'pickObjects' field", function(){

				xmlData.pickObjects[0].split(',').length.should.equal(10);
			});

			it("'pickObjects' should be in the correct format", function(){

				var pickArray = xmlData.pickObjects[0].split(',');

				for (var i=0; i<pickArray.length; i++)
				{
					// The pick objects must be equal to or greater than -2
					if (parseInt(pickArray[i]) < -2)
					{
						throw new Error("Invalid 'pickObjects' element of " + pickArray[i] + " (must be >= -2)");
					}
				}
			});
		});

		describe("Bonus Gameplay", function(){

			// Run a whole bunch of spins to try and get a bonus state
			bonusPick = null;

			it ("Should get a bonus state after at most " + numberOfSpins + " spins", function(){

				// Run full games until we get a bonus state (up to however many spins)
				spinCount = 0;

				while (spinCount++ <= numberOfSpins && !bonusPick)
				{
					spinState = game.createState(totalSpins, totalSeconds);

					while (spinState.spinsLeft > 0)
					{
						var spinData = game.spin(spinState);
						spinState = spinData.state;

						if (spinState.bonusPick)
						{
							bonusPick = spinState.bonusPick
							break;
						}
					}
				}

				// Error if we never got a bonus pick
				if (!bonusPick) throw new Error("No bonusPick after " + numberOfSpins + " spins!");
			});

			it ("'bonusPick.wheel' should be identical to 'wheelWedges' in math XML", function(){

				bonusPick.should.have.property("wheel");

				wedgesArr = xmlData.wheelWedges[0].split(',');
				bonusPick.wheel.length.should.equal(wedgesArr.length);

				for (var i=0; i<bonusPick.wheel.length; i++)
				{
					parseInt(bonusPick.wheel[i]).should.equal(parseInt(wedgesArr[i]));
				}
			});

			it ("'bonusPick.mods' should contain all of the pickObjects defined in math XML", function(){

				bonusPick.should.have.property("mods");

				// Populate an array with the expected values from the math XML, in the expected format,
				// FROM MATH XML "Numbers > 0 are multipliers, 0 is a spin of the wheel, -1 are pointers that are added, -2 is a pooper"

				var pickArray = xmlData.pickObjects[0].split(',');
				bonusPick.mods.length.should.equal(pickArray.length);

				// Parse the numeric values from the xml into the format expected by the client and check values
				for (var i=0; i<pickArray.length; i++)
				{	
					if (parseInt(pickArray[i]) > 0){
						pickArray[i] = pickArray[i] + "x";
					}
					else if (parseInt(pickArray[i]) == 0){

						pickArray[i] = "freespin";
					}
					else if (parseInt(pickArray[i]) == -1){

						pickArray[i] = "pointer";
					}
					else if (parseInt(pickArray[i]) == -2){

						pickArray[i] = "pooper";
					}

					// Search the returned picks for the parsed value
					for (var j=0; j<bonusPick.mods.length; j++)
					{
						if (bonusPick.mods[j].indexOf(pickArray[i]) != -1)
						{
							pickArray.splice(i--, 1);
							break;
						}
					}
				}

				// If there are still any bonus picks left, it means we didn't include them all
				pickArray.length.should.equal(0);
			});

			it ("'bonusPick' field should contain 'bonusWin'", function(){

				bonusPick.should.have.property("bonusWin");
			});

			it ("'bonusPick' field should contain 'totalWin'", function (){

				bonusPick.should.have.property("totalWin");
			});

			it ("Score should match calulations based off of provided mods", function (){

				var mult = 0;
				var pointArr = [1];
				var score = 0;

				// First calculate the multiplyer and pointers
				for (var i=0; i<bonusPick.mods.length; i++){

					if (bonusPick.mods[i].indexOf('x') != -1){

						mult += parseInt(bonusPick.mods[i].slice(0, -1))
					}
					else if (bonusPick.mods[i].indexOf("pointer") != -1){

						pointArr.push(parseInt(bonusPick.mods[i].slice(7)))
					}
					else if (bonusPick.mods[i].indexOf("pooper") != -1){

						break;
					}
				}

				// Now calculate spins
				for (var i=0; i<bonusPick.mods.length; i++)
				{

					if (bonusPick.mods[i].indexOf("freespin") != -1){

						offset = parseInt(bonusPick.mods[i].slice(8));

						score += calcSpinScore(bonusPick.wheel, offset, mult, pointArr);
					}
					else if (bonusPick.mods[i].indexOf("pooper") != -1){

						offset = parseInt(bonusPick.mods[i].slice(6));

						score += calcSpinScore(bonusPick.wheel, offset, mult, pointArr);
						break;
					}
				}

				bonusPick.bonusWin.should.equal(score);
			});
		});

		describe("Bonus Game Aspects", function(){

			it ("Should always get pointers in new positions over " + numberOfBonus + " bonuses", function(){

				this.timeout(0);

				bonusCount = 0;

				while (bonusCount < numberOfBonus){

					spinState = game.createState(totalSpins, totalSeconds);

					while (spinState.spinsLeft > 0){

						var spinData = game.spin(spinState);
						spinState = spinData.state;

						if (spinState.bonusPick){

							bonusCount++;
							//Log the current bonus count every 100 bonuses
							if (bonusCount % 100 == 0)
								console.log("Curent Bonus Count: " + bonusCount);

							var currentPointers = [1];

							var bonusPick = spinState.bonusPick
							
							for (var i=0; i<bonusPick.mods.length; i++){

								if (bonusPick.mods[i].indexOf("pointer") != -1){

									// For every pointer returned, make sure that it is a new pointer
									var pointerValue = parseInt(bonusPick.mods[i].slice(7))

									for (var j=0; j<currentPointers.length; j++){

										currentPointers[j].should.not.equal(pointerValue);
									}

									currentPointers.push(pointerValue);
								}
							}
						}
					}
				}
			});
			it ("Should never get a pooper in the first four bonus picks over " + numberOfBonus + " bonuses", function(){

				this.timeout(0);

				bonusCount = 0;

				while (bonusCount < numberOfBonus){

					spinState = game.createState(totalSpins, totalSeconds);

					while (spinState.spinsLeft > 0){

						var spinData = game.spin(spinState);
						spinState = spinData.state;

						if (spinState.bonusPick){

							bonusCount++;
							//Log the current bonus count every 100 bonuses
							if (bonusCount % 100 == 0)
								console.log("Curent Bonus Count: " + bonusCount);

							var bonusPick = spinState.bonusPick
							
							for (var i=0; i<bonusPick.mods.length; i++){

								if (bonusPick.mods[i].indexOf("pooper") != -1){

									if (i < 4)
										throw new Error("Pooper in a bonus pick index less than 4!")
								}
							}
						}
					}
				}
			});
		});
	});
}

function bonusTime() {
	describe("Bonus Time", function() {
		timeData = [];

		it ("Should be able to collect time data over " + numberOfSpins + " spins without errors", function() {

			// Run full games up to 1000 spins and store timing data for later analysis
			var spinCount = 0;

			for (var i=0; ; i++)
			{
				spinState = game.createState(totalSpins, totalSeconds);
				timeData[i] = [];

				while (spinState.spinsLeft > 0)
				{
					var spinData = game.spin(spinState);
					spinState = spinData.state;

					timeData[i].push({ secsLeft: spinState.secsLeft,
						secsTotal: spinState.secsTotal,
						gotBonus: spinState.bonusPick ? true : false
					})

					spinCount++;
				}

				if (spinCount > numberOfSpins) break;
			}
		})

		it ("secsTotal and secsLeft should only increase during a bonus", function() {
			var secondsToAdd = parseInt(xmlData.pickSecsAdded);
			for (var i=0; i<timeData.length; i++) {

				var lastTimeData = timeData[i][0];
				for (var j=1; j<timeData.length; j++) {

					// Check secsRemaining with some leeway just in case we managed to squeeze in between seconds
					if (timeData[i][j].gotBonus)
						timeData[i][j].secsLeft.should.be.within(lastTimeData.secsLeft + secondsToAdd - 5, lastTimeData.secsLeft + secondsToAdd + 5);
					else
						timeData[i][j].secsLeft.should.be.within(lastTimeData.secsLeft - 5, lastTimeData.secsLeft + 5);

					lastTimeData = timeData[i][j];
				}
			}
		});
	});
}

// Run the test!
run();

/** Helpers **/
function calcSpinScore(wedges, wedgeOffset, mult, pointArr){
	score = 0
	for (var i=0; i<pointArr.length; i++){

		// Subtract 1 because the client expects the first index to be 1
		score += parseInt(wedges[(pointArr[i] - 1 + wedgeOffset - 1) % wedges.length]) * (mult ? mult : 1);
	}

	return score;
}
