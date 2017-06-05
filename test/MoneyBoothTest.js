/*
	Testing for the Money Booth game
*/

/** Package requirements **/
var fs = require('fs');
var should = require('should');
var xml2js = require('xml2js');

/** Custom package requirements **/
var common = require('../include/common');
var SlotSession = require('../classes/data/SlotSession').SlotSession;

/** Slot games **/
var MoneyBoothGame = require("../classes/games/MoneyBoothGame").MoneyBoothGame;

/** Settings Variables **/
var numberOfSpins = 1000;
var totalSeconds = 300;
var totalSpins = 26;
var fsMaxSpins = 30;
var xmlFileName = "./xml/math/moneybooth.xml";

/** Global Variables **/
var game = null;
var parser = new xml2js.Parser({trim:true});
var xmlString = null;
var xmlData = null;

/** Test Code **/

// "main" testing function
function run(){

	describe("MoneyBooth", function(){

		findXML();
		parseXML();
		loadGame();
		singleSpin(); // Start by doing a single spin
		fullGame();
		bonusGame();
	});

}

// Find the XML for this game
function findXML(){
	describe("Find XML", function(){
		it("Game XML titled 'moneybooth.xml' should be found in './xml/math'", function(done){

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
		it ("Game XML should contain the id 'moneybooth'", function(){

			xmlData.$.id.should.equal("moneybooth");
		});

		it ("Game should initialize without errors", function(){

			game = new MoneyBoothGame();
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

		var bonusSpins = 0;

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

// Bonus game testing
function bonusGame(){
	describe("Bonus Game", function(){
		it("Should get at least one bonus over " + numberOfSpins + " spins", function(){

			this.timeout(0);
			
			var gotBonus = false;
			for (var i=0; i < numberOfSpins; i++) {
				
				// Bonus spins are just as likely on the first spin as any other spin. We don't need to run full games
				var spinState = game.createState(totalSpins, totalSeconds);
				var spinData = game.spin(spinState);
				
				if (spinData.state.bonusInfo) {
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
					if (spinState.secsTotal > totalTime) {
						
						if (!spinState.bonusInfo) throw new Error("Time increased without a Pick Bonus!");
						
						totalTime = spinState.secsTotal;
					}
				}
			}
		});
		
		it("Bonus Game should have the correct number of picks", function(){
			
			var spinState = game.createState(totalSpins, totalSeconds);
			var spinData = game.spin(spinState, { params: { cheat: "B1,P1,P1,P1,P1,B2,P1,P1,P1,P1,B3,P1,P1,P1,P1" } });
			
			spinData.state.bonusInfo.numberOfPicks.should.equal(1);
			
			spinState = game.createState(totalSpins, totalSeconds);
			spinData = game.spin(spinState, { params: { cheat: "B1,P1,B1,P1,P1,B2,P1,B2,P1,P1,B3,P1,B3,P1,P1" } });
			
			spinData.state.bonusInfo.numberOfPicks.should.equal(2);
			
			spinState = game.createState(totalSpins, totalSeconds);
			spinData = game.spin(spinState, { params: { cheat: "B1,P1,B1,P1,B1,B2,B1,B2,P1,B2,B3,P1,B3,P1,B3" } });
			
			spinData.state.bonusInfo.numberOfPicks.should.equal(3);
		});
		
		it("Bonus Symbol should only appear in win lines when a bonus game is hit", function(){
			var spinState = game.createState(totalSpins, totalSeconds);
			var spinData = game.spin(spinState, { params: { cheat: "B1,P1,P1,P1,P1,B2,P1,P1,P1,P1,B3,P1,P1,P1,P1" } });
			
			var foundResult = false;
			for (var i=0; i < spinData.spin.wins.results.length; i++){
				if (spinData.spin.wins.results[i].symbol == "B1") {
					foundResult = true;
					break;
				}
			}
			foundResult.should.equal(true);
			
			spinState = game.createState(totalSpins, totalSeconds);
			spinData = game.spin(spinState, { params: { cheat: "P1,P1,P1,P1,P1,B1,P1,P1,P1,P1,P1,P1,P1,P1,P1" } });
			
			foundResult = false;
			for (var i=0; i < spinData.spin.wins.results.length; i++){
				if (spinData.spin.wins.results[i].symbol == "B1") {
					foundResult = true;
					break;
				}
			}
			foundResult.should.equal(false);
		})
	});
}

// Run the test!
run();

