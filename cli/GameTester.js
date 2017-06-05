/* global process */
require("coffee-script/register")
var fs = require('fs');
var readline = require("readline");
var xml2js = require('xml2js');

// Include all the games! Oh boy!
var AllGames = {};
AllGames.angrychefs = require("../classes/games/AngryChefsGame").AngryChefsGame;
AllGames.bankrollbandits = require("../classes/games/BankrollBanditsGame").BankrollBanditsGame;
AllGames.bounty = require("../classes/games/BountyGame").BountyGame;
AllGames.butterflytreasures = require("../classes/games/ButterflyTreasuresGame").ButterflyTreasuresGame;
AllGames.crusadersquest = require("../classes/games/CrusadersQuestGame").CrusadersQuestGame;
AllGames.fatcat7 = require("../classes/games/FatCat7Game").FatCat7Game;
AllGames.ghosttreasures = require("../classes/games/GhostTreasuresGame").GhostTreasuresGame;
AllGames.holidayjoy = require("../classes/games/HolidayJoyGame").HolidayJoyGame;
AllGames.moneybooth = require("../classes/games/MoneyBoothGame").MoneyBoothGame;
AllGames.oakinthekitchen = require("../classes/games/OakInTheKitchenGame").OakInTheKitchenGame;
AllGames.penguinriches = require("../classes/games/PenguinRichesGame").PenguinRichesGame;
AllGames.romancingriches = require("../classes/games/RomancingRichesGame").RomancingRichesGame;
AllGames.underseaworld2 = require("../classes/games/UnderseaWorld2Game").UnderseaWorld2Game;
AllGames.underseaworld = require("../classes/games/UnderseaWorldGame").UnderseaWorldGame;

var parser = new xml2js.Parser({trim:true});

// "Constants"
var TOTAL_SPINS = 35;
var TOTAL_SECONDS = 500;

/**
 * This program acts as a simple CLI tester for games, it will check results
 * for a single pay line, given symbols to place on that line
 * 
 * Run this program with `node GameTester <gameId>`
 */
// Check that there is a game provided, that is known to exist
var gameId = process.argv[2];

if (!gameId || gameId == "") {
	console.error("A Game ID must be provided!");
	process.exit();
}

gameId = gameId.toLowerCase();

if (!AllGames[gameId]) {
	console.error("Game ID: \"%s\" not found! Did you enter the name of the game instead of the ID?", gameId);
	process.exit();
}

// The game must exist! go get it!
var game = new AllGames[gameId]();
var state = {};

// Get the game xml
var xmlData = {};
console.log("Reading XML File...");
fs.readFile("../xml/math/" + gameId + ".xml", function(err, data){

	if (err) throw err;
	
	console.log("Parsing XML File...");
	parser.parseString(data, function(err, result){

		if (err) throw err;

		xmlData = result.math;
		
		game.importGame(xmlData);
		
		runCLI();
	});
});

function runCLI(){
	
	// Automatically start the game running
	console.log("Starting Game...");
	state = game.createState(TOTAL_SPINS, TOTAL_SECONDS);
	
	// This creates an interface that handles stdin
	var rl = readline.createInterface({
		input: process.stdin,
		output: process.stdout,
		terminal: false
	});
	
	console.log("~~CLI Running! Enter `help` for commands~~\n");
	
	// Handle stuff
	rl.on("line", function(line) {
		
		// Split the arguments
		var args = [];
		var lastIndex = 0;
		for (var i=0; i < line.length; i++) {
			if (line.charAt(i) == ' ') {
				args.push(line.slice(lastIndex, i));
				lastIndex = i + 1;
			}
		}
		args.push(line.slice(lastIndex));
		
		// Lower Case argument!
		args[0] = args[0].toLowerCase();
		
		switch(args[0]) {
			case "help":
				console.log("\nCommands:");
				console.log("`help`: Shows this dialogue");
				console.log("`quit`: Exits the CLI");
				console.log("`spin`: Makes a spin using provided arguments to fill in the top row with the requested symbol\n")
			break;
			case "quit":
				console.log("Exiting...");
				process.exit();
			break;
			case "spin":
				
				console.log("Spinning...");
				var data = makeSpin(args);
				
				console.log("Spin finished!");
				console.log("\nData:");
				console.log(data);
				console.log();
				console.log("Window:")
				console.log(data.spin.window);
				console.log();
				console.log("Win Results:");
				console.log(data.spin.wins.results);
				console.log("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");
			break;
			default:
				console.warn("\"%s\" is not a valid command! Enter `help` for a list of valid commands\n", args[0]);
		}
	});
}

function makeSpin(args) {
	
	// Make a spin using the provided arguments
	// Generate a cheat string
	var cheatString = "";
	for (var i=0; i < game.stripGroup.rows; i++) {
		for (var j=0; j < args.length - 1; j++) {
			if (i == 0) {
				cheatString += args[j + 1]
			} else {
				cheatString += "?";
			}
			
			if (i != game.stripGroup.rows - 1 || j != args.length - 2)
				cheatString += ",";
		}
	}
	
	var spinData = game.spin(state, { params: { cheat: cheatString } });
	state = spinData.state;
	
	return spinData;
}
