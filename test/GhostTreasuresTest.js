/*
	Testing for the Ghost Treasures game
*/

/** Package requirements **/
var fs = require('fs');
var should = require('should');
var xml2js = require('xml2js');

/** Custom package requirements **/
var common = require('../include/common');
var SlotSession = require('../classes/data/SlotSession').SlotSession;

/** Slot games **/
var GhostTreasuresGame = require("../classes/games/GhostTreasuresGame").GhostTreasuresGame;

/** Settings Variables **/
var numberOfSpins = 1000;
var totalSeconds = 300;
var totalSpins = 35;
var fsMaxSpins = 30;
var xmlFileName = "./xml/math/ghosttreasures.xml";

/** Global Variables **/
var game = null;
var parser = new xml2js.Parser({trim:true});
var xmlString = null;
var xmlData = null;

/** Test Code **/

// "main" testing function
function run(){

	describe("GhostTreasures", function(){

		findXML();
		parseXML();
		loadGame();
		singleSpin(); // Start by doing a single spin
		fullGame();
		freeSpins();
	});

}

// Find the XML for this game
function findXML(){
	describe("Find XML", function(){
		it("Game XML titled 'ghosttreasures.xml' should be found in './xml/math'", function(done){

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
		it ("Game XML should contain the id 'ghosttreasures'", function(){

			xmlData.$.id.should.equal("ghosttreasures");
		});

		it ("Game should initialize without errors", function(){

			game = new GhostTreasuresGame();
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
		});

		it ("Spin payout should be within bounds set in xml", function(){

			spinData.spin.wins.pay.should.be.within(xmlData.minSingleSpinAmount, xmlData.maxSingleSpinAmount);
		});

		// In the case of a single spin, there should always just be one less spin remaining than the total
		it ("Spins remaining should have decremented properly", function(){

			spinData.state.spinsLeft.should.equal(totalSpins - 1);
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
		
		it ("Should spin at least once", function() {
			timesSpun.should.be.above(0);
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
		
		it ("Free spins should be within bounds (max "+fsMaxSpins+")", function(){
			bonusSpins.should.be.below(fsMaxSpins);
		});
		
		it ("Free spins should add to total spins", function() {
			var spinData = null;
			var totalSpins = 5;
			var spinState = game.createState(totalSpins, totalSeconds);
			var freeSpinNumber = parseInt(xmlData.fsSpinsTotal[0]);
			
			spinData = game.spin(spinState, { params: { cheat: "B,A,B,A,B" } });
			spinState = spinData.state;
			
			spinState.spinsTotal.should.be.exactly(freeSpinNumber+totalSpins);
		});
		
		it ("Free spins should decrement", function () {
			var freeSpinNumber = parseInt(xmlData.fsSpinsTotal[0]);
			var spinState = game.createState(5, totalSeconds);
			
			spinData = game.spin(spinState, { params: { cheat: "B,?,B,?,B" } });
			spinState = spinData.state;
			spinState.fsSpinsLeft.should.be.exactly(freeSpinNumber);
			
			spinData = game.spin(spinState, { params: { cheat: "B,?,B,?,B" } });
			spinState = spinData.state;
			spinState.fsSpinsLeft.should.be.exactly(freeSpinNumber-1);
		});
		
		it ("Free spins left should decrement and total free spins should remain at the maximum defined in the xml", function() {
			var freeSpinNumber = parseInt(xmlData.fsSpinsTotal[0]);
			var spinState = game.createState(5, totalSeconds);

			for (var i=freeSpinNumber; i>=0; i--)
			{
				spinData = game.spin(spinState, { params: { cheat: "B,?,B,?,B" } });
				spinState = spinData.state;
				spinState.fsSpinsTotal.should.be.exactly(freeSpinNumber);
				spinState.fsSpinsLeft.should.be.exactly(i);
			}

			// Spinning one last time should result in no more free spins than the free spin number
			spinData = game.spin(spinState, { params: { cheat: "B,?,B,?,B" } });
			spinState = spinData.state;
			spinState.fsSpinsTotal.should.be.exactly(freeSpinNumber);
			spinState.fsSpinsLeft.should.be.exactly(freeSpinNumber);
		});
	});
}

// Run the test!
run();

