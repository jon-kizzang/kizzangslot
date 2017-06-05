/*
	Testing for the Fat Cat 7's game
*/

/** Package requirements **/
var fs = require('fs');
var should = require('should');
var xml2js = require('xml2js');

/** Custom package requirements **/
var common = require('../include/common');
var SlotSession = require('../classes/data/SlotSession').SlotSession;

/** Slot games **/
var FatCat7Game = require("../classes/games/FatCat7Game").FatCat7Game;

/** Settings Variables **/
var numberOfSpins = 1000;
var totalSeconds = 300;
var totalSpins = 35;
var fsMaxSpins = 30;
var xmlFileName = "./xml/math/fatcat7.xml";

/** Global Variables **/
var game = null;
var parser = new xml2js.Parser({trim:true});
var xmlString = null;
var xmlData = null;

/** Test Code **/

// "main" testing function
function run(){

	describe("FatCat7", function(){

		findXML();
		parseXML();
		loadGame();
		singleSpin(); // Start by doing a single spin
		fullGame();
		freeSpins();
		//scatters();
	});

}

// Find the XML for this game
function findXML(){
	describe("Find XML", function(){
		it("Game XML titled 'fatcat7.xml' should be found in './xml/math'", function(done){

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
		it ("Game XML should contain the id 'fatcat7'", function(){

			xmlData.$.id.should.equal("fatcat7");
		});

		it ("Game should initialize without errors", function(){

			game = new FatCat7Game();
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
		var currspins = totalSpins;
		it ("Game should create an initial state without errors", function(){

			state = game.createState(currspins, totalSeconds);
		});

		it ("Game should spin without any errors", function(){

			spinData = game.spin(state);
			currspins--;
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
				spinData.state.spinsLeft.should.equal(currspins + 5);
			else
				spinData.state.spinsLeft.should.equal(currspins);
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

function freeSpins() {
	describe("Free Spins", function(){
		var bonusSpins = 0;
		var spinData = null;
		var spinState = null;
		var numSpins = numberOfSpins;
		
		//spin a number of games
		it ("Should trigger at least one bonus over " + numberOfSpins + " spins", function() {
			while (numSpins > 0) {
				spinState = game.createState(totalSpins, totalSeconds);

				var spinsRemaining = totalSpins;

				numSpins--;
				while (spinsRemaining > 0)
				{
					spinData = game.spin(spinState);
					spinState = spinData.state;
					spinsRemaining = spinState.spinsLeft;
					
					bonusSpins = parseInt(spinData.state.spinsTotal) - totalSpins;
					numSpins--;
				}
				
				if (bonusSpins > 0) break;
			}
			
			bonusSpins.should.be.above(0);
		});
		
		it ("Free spins should add to total spins", function() {
			var spinData = null;
			var totalSpins = 5;
			var spinState = game.createState(totalSpins, totalSeconds);
			var freeSpinNumber = parseInt(xmlData.fsSpinsTotal[0]);
			
			spinData = game.spin(spinState, { params: { cheat: "B,B,B" } });
			spinState = spinData.state;
			
			spinState.spinsTotal.should.be.exactly(freeSpinNumber+totalSpins);
		});
		
		it ("Free spins should decrement", function () {
			var freeSpinNumber = parseInt(xmlData.fsSpinsTotal[0]);
			var spinState = game.createState(5, totalSeconds);
			
			spinData = game.spin(spinState, { params: { cheat: "B,B,B" } });
			spinState = spinData.state;
			spinState.fsSpinsLeft.should.be.exactly(freeSpinNumber);
			
			spinData = game.spin(spinState);
			spinState = spinData.state;
			spinState.fsSpinsLeft.should.be.exactly(freeSpinNumber-1);
		});
		
		it ("Three or more bonuses in free spin mode should give that many free spins", function(){
			var freeSpinNumber = parseInt(xmlData.fsSpinsTotal[0]);
			var spinState = game.createState(5, totalSeconds);
			
			spinData = game.spin(spinState, { params: { cheat: "B,B,B" } });
			spinState = spinData.state;
			spinState.fsSpinsLeft.should.be.exactly(freeSpinNumber);
			
			spinData = game.spin(spinState, { params: { cheat: "BB,BB,BB" } });
			
			// We will have at least three bonuses, but there may be more! Count the bees!
			var bonusCount = 0;
			for (var i=0; i<spinData.spin.window.length; i++){
				for (var j=0; j<spinData.spin.window[i].length; j++){
					if (spinData.spin.window[i][j] == "BB")
						bonusCount++;
				}
			}
			
			spinState = spinData.state;
			spinState.fsSpinsLeft.should.be.exactly(freeSpinNumber + bonusCount - 1);
		});
		
		it ("Fewer than three bonus in free spin mode should not give free spins", function(){
			var freeSpinNumber = parseInt(xmlData.fsSpinsTotal[0]);
			var spinState = game.createState(5, totalSeconds);
			
			spinData = game.spin(spinState, { params: { cheat: "B,B,B" } });
			spinState = spinData.state;
			spinState.fsSpinsLeft.should.be.exactly(freeSpinNumber);
			
			// Check one bonus
			spinData = game.spin(spinState, { params: { cheat: "BB,P2,P1" } });
			spinData.state.fsSpinsLeft.should.be.exactly(freeSpinNumber - 1);
			
			// Check two bonuses
			spinData = game.spin(spinData.state, { params: { cheat: "BB,BB,P3" } });
			spinData.state.fsSpinsLeft.should.be.exactly(freeSpinNumber - 2);
		});
		
		it ("Special Free Spin Bonus Game wilds should appear in the win results when making a line of their own", function(){
			var freeSpinNumber = parseInt(xmlData.fsSpinsTotal[0]);
			var spinState = game.createState(5, totalSeconds);
			
			spinData = game.spin(spinState, { params: { cheat: "B,B,B" } });
			spinState = spinData.state;
			spinState.fsSpinsLeft.should.be.exactly(freeSpinNumber);
			
			spinData = game.spin(spinState, { params: { cheat: "W2,W5,W3,BP1,BP2,BP2,BP1,BP4,BP4" } });
			
			var foundP1 = false;
			for (var i=0; i<spinData.spin.wins.results.length; i++){
				if (spinData.spin.wins.results[i].symbol == "P1")
					foundP1 = true;
			}
			foundP1.should.equal(true);
		});
		
		it ("Should not get 3+ wilds when a bonus game hits", function(){
			var spinState = game.createState(totalSpins, totalSeconds);
			spinData = game.spin(spinState, { params: { cheat: "B,W,B,W,B,B,P1,P1,P1" } });
			
			var wildCount = 0;
			for (var j=0; j<spinData.spin.window.length; j++){
				for (var k=0; k<spinData.spin.window[j].length; k++){
					if (spinData.spin.window[j][k] == "W")
						wildCount++;
				}
			}
			
			wildCount.should.not.be.above(2);
		});
		
		it ("Wild multipliers should be additive", function(){
			var spinState = game.createState(5, totalSeconds);
			
			spinData = game.spin(spinState, { params: { cheat: "B,B,B" } });
			spinState = spinData.state;
			
			spinData = game.spin(spinState, { params: { cheat: "W4,W3,P2,P2,P3,P3,P1,P4,P4" } });
			
			spinData.spin.wins.results[0].mx.should.equal(8);
			
			// Search for and check the score generated (it should be doubled!)
			for (var i=0; i < xmlData.symbolGroup[0].symbol.length; i++) {
				
				if (xmlData.symbolGroup[0].symbol[i].$.id == "P2") {
					spinData.spin.wins.results[0].pay.should.equal(parseInt(xmlData.symbolGroup[0].symbol[i].$.pays.split(",")[2]) * 8);
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

