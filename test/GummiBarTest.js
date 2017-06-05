/*
	Testing for the Gummi Bar game
*/

/** Package requirements **/
var fs = require('fs');
var should = require('should');
var xml2js = require('xml2js');

/** Custom package requirements **/
var common = require('../include/common');
var SlotSession = require('../classes/data/SlotSession').SlotSession;

/** Slot games **/
var GummiBarGame = require("../classes/games/GummiBarGame").GummiBarGame;

/** Settings Variables **/
var numberOfSpins = 1000;
var totalSeconds = 300;
var totalSpins = 26;
var xmlFileName = "./xml/math/gummibar.xml";

/** Global Variables **/
var game = null;
var parser = new xml2js.Parser({trim:true});
var xmlString = null;
var xmlData = null;

/** Test Code **/

// "main" testing function
function run(){

	describe("GummiBar", function(){

			findXML();
			parseXML();
			loadGame();
			singleSpin(); // Start by doing a single spin
			fullGame();
			bonusGame();
			scatters();
	});

}

// Find the XML for this game
function findXML(){
	describe("Find XML", function(){
		it("Game XML titled 'gummibar.xml' should be found in './xml/math'", function(done){

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
		it ("Game XML should contain the id 'gummibar'", function(){

			xmlData.$.id.should.equal("gummibar");
		});

		it ("Game should initialize without errors", function(){

			game = new GummiBarGame();
		});

		it ("Game should import XML settings without errors", function(){

			game.importGame(xmlData);
		});
	});
}

// Do a single, initial, spin
function singleSpin(){
	describe("Single Spin", function(){

		var state = null;
		var spinData = null;

		it ("Game should create an initial state without errors", function(){

			state = game.createState(totalSpins, totalSeconds);
		});

		it ("Game should spin without any errors", function(){

			spinData = game.spin(state);
			totalSpins--;
		});
		
		it ("Window should be 3x3 (3 reels, 3 rows)", function(){
		
			spinData.spin.window.length.should.equal(3);
			
			for (var i=0; i<spinData.spin.window.length; i++)
				spinData.spin.window[i].length.should.equal(3);
        });

		it ("Spin payout should be within bounds set in xml", function(){

			spinData.spin.wins.pay.should.be.within(xmlData.minSingleSpinAmount, xmlData.maxSingleSpinAmount);
		});

		// In the case of a single spin, there should always just be one less spin remaining than the total
		it ("Spins remaining should have decremented properly", function(){

			if(spinData.state.fsOn)
				spinData.state.spinsLeft.should.equal(totalSpins + 5);
			else
				spinData.state.spinsLeft.should.equal(totalSpins);
		});
	});
}

// Spin until we run out of spins
function fullGame(){
	describe("Full Game", function(){
		var timesSpun = 0;

		// Spin until we run out of spins
		it ("Should be able to run a full game without errors", function(){

			// Timeout after 0.5 seconds
			this.timeout(500);

			var spinData = null;
			var spinState = game.createState(totalSpins, totalSeconds);
			
			//console.log(spinState);
			var spinsRemaining = totalSpins;

			while (spinsRemaining > 0)
			{
				spinData = game.spin(spinState);
				timesSpun++;
				spinState = spinData.state;
				spinsRemaining = spinState.spinsLeft;
			}
		});
		
		it ("Should spin at least " + totalSpins + " times", function() {
			timesSpun.should.be.above(totalSpins - 1);
		});
	});
}

// Bonus game testing
function bonusGame(){
	describe("Bonus Game", function(){
		it("Should get at least one bonus over " + numberOfSpins + " spins", function(){

			this.timeout(0);
			
			var gotBonus = false;
			for (var i=0; i < numberOfSpins; i++) {
				console.log("Runnung...");
				// Bonus spins are just as likely on the first spin as any other spin. We don't need to run full games
				var spinState = game.createState(totalSpins, totalSeconds);
				var spinData = game.spin(spinState);
				
				if (spinData.state.MainBonusInfo || spinData.state.MultiplierBonusInfo) {
					gotBonus = true;
					break;
				}
			}
			
			gotBonus.should.equal(true);
		});
		
		it("Time should not increase without a bonus. Tested over " + numberOfSpins + " spins", function(){
			
			// This may take a few seconds
			this.timeout(0);
			
			var spins = 0;
			while (spins < numberOfSpins) {
				var spinData = null;
				var spinState = game.createState(totalSpins, totalSeconds);

				var spinsRemaining = totalSpins;
				var totalTime = spinState.secsTotal;
				
				while (spinsRemaining > 0)
				{
					spinData = game.spin(spinState);
					spins++;
					spinState = spinData.state;
					spinsRemaining = spinState.spinsLeft;
					
					//console.log("Seconds Server: Seconds Test   : " + spinState.secsTotal + ":" + totalTime);
					
					//console.log("Main Bonus Info: " + JSON.stringify(spinState.MainBonusInfo));
					//console.log("Multiplier Bonus Info: " + JSON.stringify(spinState.MultiplierBonusInfo));
					
					if (spinState.MainBonusInfo || spinState.MultiplierBonusInfo)
						totalTime = spinState.secsTotal;
					
					if (spinState.secsTotal > totalTime) 
					{
						if (!spinState.MainBonusInfo || !spinState.MultiplierBonusInfo) 
							throw new Error("Time increased without a Pick Bonus!");
						
						totalTime = spinState.secsTotal;
					}
				}
			}
		});
	});
}

function scatters(){
	describe("Scatters", function(){
		it("All scatters should have the same ID over " + numberOfSpins + " spins", function (){
			
			for (var i=0; i<numberOfSpins; i++) {
				
				// Make a game with 1 spin
				var spinData = null;
				var spinState = null;
				
				spinState = game.createState(totalSpins, totalSeconds);
				spinData = game.spin(spinState);
				
				// Check for Scatters, there should only be one kind of scatter!
				var foundScatter = "";
				for (var j=0; j<spinData.spin.window.length; j++) {
					for (var k=0; k<spinData.spin.window[j].length; k++) {
						var sym = spinData.spin.window[j][k];
						if (!foundScatter && (sym == "S2" || sym == "S3" || sym == "S4")) {
							
							foundScatter = sym;
							continue;
						} else if ((sym == "S2" || sym == "S3" || sym == "S4") && sym != foundScatter) {
							
							throw new Error("FOUND DIFFERENT SCATTER. Expected: " + foundScatter + " Actual: " + sym);
						}
					}
				}
			}
		});
	});
}

// Run the test!
run();

