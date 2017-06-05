/*
	Testing for the Oak in the Kitchen game
*/

/** Package requirements **/
var fs = require('fs');
var should = require('should');
var xml2js = require('xml2js');

/** Custom package requirements **/
var common = require('../include/common');
var SlotSession = require('../classes/data/SlotSession').SlotSession;

/** Slot games **/
var OakInTheKitchenGame = require("../classes/games/OakInTheKitchenGame").OakInTheKitchenGame;

/** Settings Variables **/
var numberOfBonus = 100;
var numberOfSpins = 1000;
var totalSeconds = 300;
var totalSpins = 35;
var fsMaxSpins = 30;
var xmlFileName = "./xml/math/oakinthekitchen.xml";

/** Global Variables **/
var game = null;
var parser = new xml2js.Parser({trim:true});
var xmlString = null;
var xmlData = null;

/** Global "Constants" **/
var POOPER = "pooper";
var CONDIMENT = "condiment";
var SIDE = "side";

/** Test Code **/

// "main" testing function
function run(){

	describe("OakInTheKitchen", function(){

		findXML();
		parseXML();
		loadGame();
		singleSpin(); // Start by doing a single spin
		fullGame();
		bonusGame();
		bonusTime();
	});

}

// Find the XML for this game
function findXML(){
	describe("Find XML", function(){
		it("Game XML titled 'oakinthekitchen.xml' should be found in './xml/math'", function(done){

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
		it ("Game XML should contain the id 'oakinthekitchen'", function(){

			xmlData.$.id.should.equal("oakinthekitchen");
		});

		it ("Game should initialize without errors", function(){

			game = new OakInTheKitchenGame();
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
				spinState = spinData.state;
				spinsRemaining = spinState.spinsLeft;
			}
		});
	});
}

// Test the requirements of the bonus game
function bonusGame(){
	describe("Bonus Game", function(){
		describe("XML Verification", function(){
			it("Math XML should contain an 'itemGroupPayout' field", function(){

				xmlData.itemGroupPayout.should.not.equal(null);
			});
			
			//Example: name="s1" ref="Soda" type="side" quantity="1" value="0"
			it("Each element of 'itemGroupPayout' should contain the fields 'name', 'ref', 'type', 'quantity', and 'value'", function(){

				for(var i=0; i<xmlData.itemGroupPayout[0].payout.length; i++){
					xmlData.itemGroupPayout[0].payout[i].$.name.should.not.equal(null);
					xmlData.itemGroupPayout[0].payout[i].$.ref.should.not.equal(null);
					xmlData.itemGroupPayout[0].payout[i].$.type.should.not.equal(null);
					xmlData.itemGroupPayout[0].payout[i].$.quantity.should.not.equal(null);
					xmlData.itemGroupPayout[0].payout[i].$.value.should.not.equal(null);
					xmlData.itemGroupPayout[0].payout[i].$.should.not.have.ownProperty("multiplier"); // This property should no longer be present
				}
			});
			
			it("'itemGroupPayout' should contain at least one pooper, one side, and seven condiments", function(){
				
				var pooperCount = 0;
				var sideCount = 0;
				var condimentCount = 0;
				
				for(var i=0; i<xmlData.itemGroupPayout[0].payout.length; i++){
					
					if (xmlData.itemGroupPayout[0].payout[i].$.type == "pooper"){
						pooperCount++;
						continue;
					}
					
					if (xmlData.itemGroupPayout[0].payout[i].$.type == "side"){
						sideCount++;
						continue;
					}
					
					if (xmlData.itemGroupPayout[0].payout[i].$.type == "condiment") condimentCount++;
				}
				
				pooperCount.should.be.within(1, Infinity);
				sideCount.should.be.within(1, Infinity);
				condimentCount.should.be.within(3, Infinity);
			});
		});

		describe("Bonus Gameplay", function(){

			// Run a whole bunch of spins to try and get a bonus state
			var bonusPick = null;

			it ("Should get a bonus state after at most " + numberOfSpins + " spins", function(){

				// Run full games until we get a bonus state (up to however many spins)
				var spinCount = 0;

				while (spinCount++ <= numberOfSpins && !bonusPick){
					var spinState = game.createState(totalSpins, totalSeconds);

					while (spinState.spinsLeft > 0){
						var spinData = game.spin(spinState);
						spinState = spinData.state;

						if (spinState.bonusPick){
							bonusPick = spinState.bonusPick;
							break;
						}
					}
				}

				// Error if we never got a bonus pick
				if (!bonusPick) throw new Error("No bonusPick after " + numberOfSpins + " spins!");
			});

			it ("'bonusPick.mods' should only contain names found in the math xml", function(){
//				console.log(bonusPick.mods);
				bonusPick.should.have.property("mods");

				var payoutArray = xmlData.itemGroupPayout[0].payout;

				for (var i=0; i<bonusPick.mods.length; i++){
					var foundName = false;
					for (var j=0; j<payoutArray.length; j++){

						if (parseMod(bonusPick.mods[i]).name == payoutArray[j].$.name)
							foundName = true;
					}

					if (!foundName)
						throw new Error("Found name " + bonusPick.mods[i] + " in 'bonusPick.mods' that is not in math xml")
				}
			});
			
			it ("'bonusPick.mods' should contain at least one pooper", function(){
				
				var foundPooper = false;
				
				for (var i=0; bonusPick.mods.length; i++){
					
					if (parseMod(bonusPick.mods[i]).type == POOPER){
						foundPooper = true;
						break;
					}
				}
				
				foundPooper.should.equal(true);
			});
			
			it ("'bonusPick.mods' should contain an appropriate amount of items, taking quantities into account", function(){
				
				// Create new arrays with the elements of bonusPick.mods and the xml data
				var checkArray = bonusPick.mods.slice();
				var xmlArray = xmlData.itemGroupPayout[0].payout.slice();
				
				for (var i=0; i<checkArray.length; i++){
					for (var j=0; j<xmlArray.length; j++){
						if (parseMod(String(checkArray[i])).name == xmlArray[j].$.name){
							checkArray.splice(i--, 1);
							
							xmlArray[j].$.quantity--;
							xmlArray[j].$.quantity.should.be.above(-1);
							break;
						}
					}
				}
				
				checkArray.length.should.equal(0);
			});
			
			it ("The values attached to 'bonusPick.mods' should match the values in the math xml", function() {
				
				var payoutArray = xmlData.itemGroupPayout[0].payout;

				for (var i=0; i<bonusPick.mods.length; i++){
					for (var j=0; j<payoutArray.length; j++){
						
						var parsed = parseMod(bonusPick.mods[i]);
						if (parsed.name == payoutArray[j].$.name){
							if (parsed.type == CONDIMENT)
								parsed.value.should.equal(parseInt(payoutArray[j].$.value));
						}
					}
				}
			});
			
			it ("bonusPick.mods' should not contain any data after the pooper", function() {
				
				for (var i=0; i<bonusPick.mods.length; i++){
					
					// Count up (with the for loop) until we hit the pooper
					if (parseMod(bonusPick.mods[i]).type == POOPER)
						break;
				}
				
				i.should.equal(bonusPick.mods.length - 1);
			});

			it ("'bonusPick' field should contain 'bonusWin'", function(){

				bonusPick.should.have.property("bonusWin");
			});

			it ("'bonusPick' field should contain 'totalWin'", function (){

				bonusPick.should.have.property("totalWin");
			});

			it ("Score should match calculations based off of provided mods", function (){

				var mult = 1;
				var score = 0;
				var gotPooper = false;
				
				var modMult = 1;
				var modScore = 0;

				var payoutArray = xmlData.itemGroupPayout[0].payout;

				// First calculate the multiplyer and pointers
				for (var i=0; i<bonusPick.mods.length; i++){
					for (var j=0; j<payoutArray.length; j++){
						
						var parsed = parseMod(bonusPick.mods[i]);
						if (parsed.name == payoutArray[j].$.name && !gotPooper){
							
							if (parsed.type == SIDE) mult++;

							score += parseInt(payoutArray[j].$.value);

							if (payoutArray[j].$.type == "pooper") gotPooper = true;
						}
					}
					
					if (gotPooper) break;
					
					// Also count the score and multiplier we get from the mods, to make sure those are accurate
					parsed = parseMod(bonusPick.mods[i]);
					
					if (parsed.type == CONDIMENT) {
						
						modScore += parsed.value;
					}
					else if (parsed.type == SIDE) {

						modMult++;
					}
				}

				score *= mult;
				modScore *= modMult;

				bonusPick.bonusWin.should.equal(modScore);
				bonusPick.bonusWin.should.equal(score);
			});
			
			var morePicks = [];
			
			it ("Should always have at least 3 condiments over " + numberOfBonus + " bonus games", function() {
				
				morePicks.push(bonusPick);
				
				while (morePicks.length < numberOfBonus) {
					
					// Run full games until we fill up on bonus picks
					var spinState = game.createState(totalSpins, totalSeconds);

					while (spinState.spinsLeft > 0){
						var spinData = game.spin(spinState);
						spinState = spinData.state;

						if (spinState.bonusPick){
							morePicks.push(spinState.bonusPick);
							break;
						}
					}
				}
				
				var condimentCount = 0;
				for (var i=0; i<morePicks.length; i++) {
					for (var j=0; j<morePicks[i].mods.length; j++) {
						
						var parsed = parseMod(morePicks[i].mods[j]);

						if  (parsed.type == CONDIMENT)
							condimentCount++;
					}
					
					condimentCount.should.be.above(2);
				}
			});
			
			it ("Should never have more than 25 mods over " + numberOfBonus + " bonus games", function() {
				
				for (var i=0; i<morePicks.length; i++) {
					
					morePicks[i].mods.length.should.be.below(26);
				}
			});
		});
	});
}

function bonusTime() {
	describe("Bonus Time", function() {
		var timeData = [];

		it ("Should be able to collect time data over " + numberOfSpins + " spins without errors", function() {

			// Run full games up to 1000 spins and store timing data for later analysis
			var spinCount = 0;

			for (var i=0; ; i++)
			{
				var spinState = game.createState(totalSpins, totalSeconds);
				timeData[i] = [];

				while (spinState.spinsLeft > 0)
				{
					var spinData = game.spin(spinState);
					spinState = spinData.state;

					timeData[i].push({ secsLeft: spinState.secsLeft,
						secsTotal: spinState.secsTotal,
						gotBonus: spinState.bonusPick ? true : false
					});

					spinCount++;
				}

				if (spinCount > numberOfSpins) break;
			}
		});

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

/**
 * Helpers
 */
function parseMod(mod){
	
	var retObject = { name: null, value: null, type: null };
	if (mod.indexOf('_') == -1) {
		// There is no data other than the name
		retObject.name = mod;
	}
	else {
		// We have extra data to deal with!
		retObject.name = mod.slice(0, mod.indexOf('_'));
		retObject.value = parseInt(mod.slice(mod.indexOf('_') + 1, mod.length));		
	}
	
	// Determine the type from the name
	if (retObject.name.indexOf('c') != -1)
		retObject.type = "condiment";
	else if (retObject.name.indexOf('s') != -1)
		retObject.type = "side";
	else if (retObject.name.indexOf('p') != -1)
		retObject.type = "pooper";
	else
		throw new Error("Unknown mod type! Mod name: " + retObject.name);
		
	return retObject;
}
