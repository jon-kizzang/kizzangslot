/* global it */
/* global describe */
/*
	Testing for the Butterfly Treasures game
*/

/** Package requirements **/
var fs = require('fs');
var should = require('should');
var xml2js = require('xml2js');

/** Custom package requirements **/
var common = require('../include/common');
var SlotSession = require('../classes/data/SlotSession').SlotSession;

/** Slot games **/
var PenguinRichesGame = require("../classes/games/PenguinRichesGame").PenguinRichesGame;

/** Settings Variables **/
var numberOfSpins = 1000;
var numberOfWildSpins = 1000;
var numberOfScatterHits = 1;
var totalSeconds = 300;
var totalSpins = 35;
var xmlFileName = "./xml/math/penguinriches.xml";

/** Global Variables **/
var game = null;
var parser = new xml2js.Parser({trim:true});
var xmlString = null;
var xmlData = null;

/** Test Code **/

// "main" testing function
function run(){

	describe("PenguinRiches", function(){

		findXML();
		parseXML();
		loadGame();
		singleSpin(); // Start by doing a single spin
		fullGame();
		freeSpins();
		freeSpinBonus();
		expandingWilds();
		scatters();
	});
}

// Find the XML for this game
function findXML(){
	describe("Find XML", function(){
		it("Game XML titled 'penguinriches.xml' should be found in './xml/math'", function(done){

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
		it ("Game XML should contain the id 'penguinriches'", function(){

			xmlData.$.id.should.equal("penguinriches");
		});

		it ("Game should initialize without errors", function(){

			game = new PenguinRichesGame();
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
		
		it ("Free spins should add to total spins", function() {
			var spinData = null;
			var totalSpins = 5;
			var spinState = game.createState(totalSpins, totalSeconds);
			var freeSpinNumber = parseInt(xmlData.fsSpinsTotal[0]);
			
			spinData = game.spin(spinState, { params: { cheat: "B,?,B,?,B" } });
			spinState = spinData.state;
			
			spinState.spinsTotal.should.be.exactly(freeSpinNumber+totalSpins);
		});
		
		it ("Free spins should decrement", function () {
			var freeSpinNumber = parseInt(xmlData.fsSpinsTotal[0]);
			var spinState = game.createState(5, totalSeconds);
			
			spinData = game.spin(spinState, !spinState.fsOn ? { params: { cheat: "B,?,B,?,B" } } : null);
			spinState = spinData.state;
			spinState.fsSpinsLeft.should.be.exactly(freeSpinNumber);
			
			spinData = game.spin(spinState, !spinState.fsOn ? { params: { cheat: "B,?,B,?,B" } } : null);
			spinState = spinData.state;
			spinState.fsSpinsLeft.should.be.exactly(freeSpinNumber-1);
		});
	});
}

function freeSpinBonus() {
	describe("Free Spin Bonus", function (){
		it("Bonus multiplier should increase fsMxTotal by 1", function(){
			var spinData = null;
			var spinState = null;
			
			spinState = game.createState(totalSpins, totalSeconds);
			
			// There must be at least three multipliers
			spinData = game.spin(spinState, { params: { cheat: "BMS,BMS,BMS,BMS,BMS" }});
			
			spinData.state.fsMxTotal.should.equal(2);
		});
		
		it("Bonus multiplier should not increase over the value defined in the math xml", function(){
			
			var spinData = null;
			var spinState = null;
			
			spinState = game.createState(totalSpins, totalSeconds);
			for (var i=0; i <= xmlData.maxFreeSpinMultiplier[0]*2; i++) {
				spinData = game.spin(spinState, { params: { cheat: "BMS,BMS,BMS,BMS,BMS" }});
				spinState = spinData.state;
			}
			
			spinState.fsMxTotal.should.equal(parseInt(xmlData.maxFreeSpinMultiplier[0]));
		});
		
		it("Bonus multiplier should reset after a bonus game ends", function(){
			var spinData = null;
			var spinState = null;
			
			spinState = game.createState(totalSpins, totalSeconds);
			for (var i=0; i <= xmlData.maxFreeSpinMultiplier[0]; i++) {
				spinData = game.spin(spinState, { params: { cheat: "BMS,BMS,BMS,BMS,BMS" }});
				spinState = spinData.state;
			}
			
			spinData = game.spin(spinState, { params: { cheat: "B,?,B,?,B" }});
			spinState = spinData.state;
			
			while (spinState.fsOn) {
				spinData = game.spin(spinState);
				spinState = spinData.state;
			}
			
			spinState.fsMxTotal.should.equal(1);
		});
		
		it("Bonus symbols should not be present in a bonus game", function(){
			var spinData = null;
			var spinState = null;
			
			spinState = game.createState(totalSpins, totalSeconds);
			
			spinData = game.spin(spinState, { params: { cheat: "B,B,B,B,B" }});
			spinState = spinData.state;
			
			spinData = game.spin(spinState, { params: { cheat: "B,B,B,B,B" }});
			spinState = spinData.state;
			
			determineSymbolPresence(spinData.spin.window, "B").should.equal(0);
		});
		
		it("Bonus multiplier symbols should not appear in pay lines", function(){
			var spinData = null;
			var spinState = null;
			
			spinState = game.createState(totalSpins, totalSeconds);
			
			spinData = game.spin(spinState, { params: { cheat: "BMS,BMS,BMS,BMS,BMS" }});
			
			for (var i=0; i < spinData.spin.wins.results.length; i++)
				spinData.spin.wins.results[i].symbol.should.not.equal("BMS");
		});
		
		it("Wilds and / or Other scatters should not appear with active bonus symbols over " + numberOfSpins + " spins", function() {
			
			for (var i=0; i<numberOfSpins; i++) {
				
				var spinState = game.createState(totalSpins, totalSeconds);
				var spinData = game.spin(spinState, { params: { cheat: "B,?,B,?,B"}});
				
				// Check for other bonuses
				for (var j=0; j < spinData.spin.window.length; j++){
					
					var foundBonus = false;
					
					for (var k=0 ; k<spinData.spin.window[j].length; k++){
						
						var sym = spinData.spin.window[j][k];
						
						if (sym == "W" || sym == "BMS" || sym.indexOf("BPS") != -1) {
							
							// Bonus symbol found! Bad Bad Bad!
							console.log(spinData.spin.window);
							throw new Error("Wild / Scatter found with bonuses! Found: " + sym);
						}
					}
				}
			}
		});
	});
}

function expandingWilds() {
	describe("Expanding Wilds", function (){
		it("All wilds should be properly expanded over " + numberOfWildSpins + " spins", function (){
			
			var foundAWild = false; // If we found at least 1 wild
			
			for (var i=0; i<numberOfWildSpins; i++) {
				
				// Make a game with 1 spin
				var spinData = null;
				var spinState = null;
				
				spinState = game.createState(totalSpins, totalSeconds);
				spinData = game.spin(spinState);
				
				// Check for wilds
				//spinData.spin.window
				for (var j=0; j < spinData.spin.window.length; j++){
					
					var foundWild = false;
					
					for (var k=0 ; k<spinData.spin.window[j].length; k++){
						
						if (foundWild && spinData.spin.window[j][k] != 'W'){
							console.error(spinData.spin.window);
							throw new Error("Wild not expanded properly!");
						}
						
						if (spinData.spin.window[j][k] == 'W'){
							foundWild = foundAWild = true;
						}
					}
				}
			}
			
			foundAWild.should.equal(true);
		});
	});
}

function scatters() {
	describe("Scatters", function (){
		it("There should be no Wild Scatters over " + numberOfSpins + " spins", function (){
			
			for (var i=0; i<numberOfSpins; i++) {
				
				// Make a game with 1 spin
				var spinData = null;
				var spinState = null;
				
				spinState = game.createState(totalSpins, totalSeconds);
				spinData = game.spin(spinState);
				
				// Check for wilds
				for (var j=0; j<spinData.spin.window.length; j++) {
					for (var k=0; k<spinData.spin.window[j].length; k++) {
						spinData.spin.window[j][k].should.not.equal("WS"); // No Wild scatters!
					}
				}
			}
		});
		
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
						if (!foundScatter && (sym == "BPS1" || sym == "BPS2" || sym == "BPS3" || sym == "BMS")) {
							
							foundScatter = sym;
							continue;
						} else if ((sym == "BPS1" || sym == "BPS2" || sym == "BPS3" || sym == "BMS") && sym != foundScatter) {
							
							throw new Error("FOUND DIFFERENT SCATTER. Expected: " + foundScatter + " Actual: " + sym);
						}
					}
				}
			}
		});
		
		it("Should never see the placeholder symbol over " + numberOfSpins + " spins", function (){
			
			for (var i=0; i<numberOfSpins; i++) {
				
				// Make a game with 1 spin
				var spinData = null;
				var spinState = null;
				
				spinState = game.createState(totalSpins, totalSeconds);
				spinData = game.spin(spinState);
				
				// We should never ever see the null scatter!
				for (var j=0; j<spinData.spin.window.length; j++) {
					for (var k=0; k<spinData.spin.window[j].length; k++) {
						spinData.spin.window[j][k].should.not.equal("NULLS");
					}
				}
			}
		});
		
		it("Should see at least " + numberOfScatterHits + " scatter hits over " + numberOfSpins + " spins", function (){
			
			var scatterCount = 0;
			for (var i=0; i<numberOfSpins; i++) {
				
				// Make a game with 1 spin
				var spinData = null;
				var spinState = null;
				
				spinState = game.createState(totalSpins, totalSeconds);
				spinData = game.spin(spinState);
				
				for (var j=0; j<spinData.spin.wins.results.length; j++)
					
					var resultId = spinData.spin.wins.results[j].symbol;
					
					if (resultId == "BPS1" || resultId == "BPS2" || resultId == "BPS3" || resultId == "BMS")
						
						scatterCount++;
			}
			
			scatterCount.should.be.above(numberOfScatterHits - 1);
		});
		
		it("Scatters should generate score when more than 3 are present", function(){
			var spinData = null;
			var spinState = null;
			var count = 0;
			
			do {
				spinState = game.createState(totalSpins, totalSeconds);
				spinData = game.spin(spinState, { params: { cheat: "BPS1,BPS1,BPS1,BPS1,BPS1" }});
				spinState = spinData.state;
				
				count = determineSymbolPresence(spinData.spin.window, "BPS1")
				
			// First make sure that there ARE more than 3 BPS1 symbols, the expanding wilds can ruin cheating
			} while(count <= 3);
			
			var foundResult = false;
			for (var i=0; i<spinData.spin.wins.results.length; i++){
				if (spinData.spin.wins.results[i].symbol == "BPS1") {
					foundResult = true;
					break;
				}
			}
			
			foundResult.should.equal(true);
		});
	});
}

// Helper will determine if there is a certain symbol present over a given number of times
function determineSymbolPresence(window, sym) {
	
	var count = 0;
	for (var i=0; i < window.length; i++) {
		for (var j=0; j < window[i].length; j++) {
			if (window[i][j] == sym) count++;
		}
	}
	
	return count;
}

// Run the test!
run();

