/*
	Testing for the Payment Panic game
*/

/** Package requirements **/
var fs = require('fs');
var should = require('should');
var xml2js = require('xml2js');

/** Custom package requirements **/
var common = require('../include/common');
var SlotSession = require('../classes/data/SlotSession').SlotSession;

/** Slot games **/
var PaymentPanicGame = require("../classes/games/PaymentPanicGame").PaymentPanicGame;

/** Settings Variables **/
var numberOfSpins = 1000;
var totalSeconds = 300;
var totalSpins = 35;
var fsMaxSpins = 30;
var xmlFileName = "./xml/math/paymentpanic.xml";

/** Global Variables **/
var game = null;
var parser = new xml2js.Parser({trim:true});
var xmlString = null;
var xmlData = null;

/** Test Code **/

// "main" testing function
function run(){

	describe("PaymentPanic", function(){

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
		it("Game XML titled 'paymentpanic.xml' should be found in './xml/math'", function(done){

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
		it ("Game XML should contain the id 'paymentpanic'", function(){

			xmlData.$.id.should.equal("paymentpanic");
		});

		it ("Game should initialize without errors", function(){

			game = new PaymentPanicGame();
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
				
				if (spinData.state.pickBonus) {
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
						
						if (!spinState.pickBonus) throw new Error("Time increased without a Pick Bonus!");
						
						totalTime = spinState.secsTotal;
					}
				}
			}
		});
	});
}

// Run the test!
run();

