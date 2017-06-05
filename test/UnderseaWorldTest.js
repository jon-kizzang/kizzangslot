/*
	Testing for the Romancing Riches game
*/

/** Package requirements **/
var fs = require('fs');
var should = require('should');
var xml2js = require('xml2js');

/** Custom package requirements **/
var common = require('../include/common');
var SlotSession = require('../classes/data/SlotSession').SlotSession;

/** Slot games **/
var UnderseaWorldGame = require("../classes/games/UnderseaWorldGame").UnderseaWorldGame;

/** Settings Variables **/
var numberOfGames = 1000;
var numberOfSpins = 1000;
var totalSeconds = 300;
var totalSpins = 35;
var fsMaxSpins = 30;
var xmlFileName = "./xml/math/underseaworld.xml";

/** Global Variables **/
var game = null;
var parser = new xml2js.Parser({trim:true});
var xmlString = null;
var xmlData = null;

/** Test Code **/

// "main" testing function
function run(){

	describe("UnderseaWorld", function(){

		findXML();
		parseXML();
		loadGame();
		singleSpin(); // Start by doing a single spin
		fullGame();
		scoring();

	});

}

// Find the XML for this game
function findXML(){
	describe("Find XML", function(){
		it("Game XML titled 'underseaworld.xml' should be found in './xml/math'", function(done){

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
		it ("Game XML should contain the id 'underseaworld'", function(){

			xmlData.$.id.should.equal("underseaworld");
		});

		it ("Game should initialize without errors", function(){

			game = new UnderseaWorldGame();
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
			
			spinsRemaining = totalSpins;

			while (spinsRemaining > 0)
			{
				var prevFreeSpins = spinState.fsSpinsTotal;
				spinData = game.spin(spinState);
				spinState = spinData.state;
				spinsRemaining = spinState.spinsLeft;
				
				if (prevFreeSpins < spinState.fsSpinsTotal) { 
					bonusSpins += (spinState.fsSpinsTotal - prevFreeSpins);
				}
			}
		});
		
		it ("Free spins should be within bounds (max "+fsMaxSpins+")", function(){
			bonusSpins.should.be.below(fsMaxSpins);
		});
		
		/*it ("Free spins should decrement", function () {
			var maxSpins = 15, fsMax = 10;
			var spinData = null;
			var spinState = game.createState(maxSpins, totalSeconds);
			spinState.fsOn = true; spinState.fsSpinsLeft = spinState.fsSpinsTotal = fsMax;
			spinState.fsTrigger = { name: 'trigger', spins: fsMax, secs: 60, picks: [ 'P1', 'P3', 'P2' ] };
			
			if (spinState.spinsLeft > 0) {
				spinData = game.spin(spinState);
				spinState = spinData.state;
			}
			
			spinState.spinsLeft.should.be.exactly(maxSpins-1);
			spinState.fsSpinsLeft.should.be.exactly(fsMax-1);
		});*/
	});
}

function scoring(){
	describe ("Scoring", function(){

		it ("Total score should match calculated score over " + numberOfGames + " games", function(){

			this.timeout(0);

			for (var i=0; i<numberOfGames; i++){

				var spinData = null;
				var spinState = game.createState(totalSpins, totalSeconds);

				// Score storage
				var totalScore = 0;
				var calcTotalScore = 0;
			
				//console.log(spinState);
				spinsRemaining = totalSpins;

				while (spinsRemaining > 0){

					spinData = game.spin(spinState);
					spinState = spinData.state;
					spinsRemaining = spinState.spinsLeft;

					totalScore = spinData.state.winTotal;
					calcTotalScore += spinData.spin.wins.pay;
				}

				totalScore.should.equal(calcTotalScore);
			}
		});
	});
}

// Run the test!
run();
