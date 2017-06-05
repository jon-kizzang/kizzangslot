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
var BountyGame = require("../classes/games/BountyGame").BountyGame;
var GummiBarGame = require("../classes/games/GummiBarGame").GummiBarGame;
var AprilMadnessGame = require("../classes/games/AprilMadnessGame").AprilMadnessGame;
var MoneyBoothGame = require("../classes/games/MoneyBoothGame").MoneyBoothGame;
var AstrologyAnswersGame = require("../classes/games/AstrologyAnswersGame").AstrologyAnswersGame;
var XtremeCashGame = require("../classes/games/XtremeCashGame").XtremeCashGame;
var FireHouseFrenzyGame = require("../classes/games/FireHouseFrenzyGame").FireHouseFrenzyGame;
var MonkeyMadnessGame = require("../classes/games/MonkeyMadnessGame").MonkeyMadnessGame;
var DiamondStreakGame = require("../classes/games/DiamondStreakGame").DiamondStreakGame;
var PaymentPanicGame = require("../classes/games/PaymentPanicGame").PaymentPanicGame;
var PuppyCashGame = require("../classes/games/PuppyCashGame").PuppyCashGame;

/** Settings Variables **/
var numberOfSpins = 1000;
var totalSeconds = 300;
var totalSpins = 26;
var fsMaxSpins = 30;
var xmlFileName = "./xml/math/" + process.env.npm_config_gamename + ".xml";

/** Global Variables **/
var gameName = "";
var parser = new xml2js.Parser({trim:true});
var xmlString = null;
var xmlData = null;
var isFreeSpinGame = false;
var isBothFreeSpinAndOtherBonus = false;

/** Test Code **/

// "main" testing function
function run(){

	describe("XML Tester", function(){
		
		//gameName = process.env.npm_config_gamename;
		//console.log("Testing " + gameName);
		
		//findXML();
		//parseXML();
		//loadGame();
		//StartMultiGameTest();
	});
}

// Find the XML for this game
function findXML(){
	describe("Find XML", function(){
		it("Game XML titled '" + gameName + ".xml' should be found in './xml/math'", function(done){
			
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
		it ("Game XML should contain the id '" + gameName + "'", function(){

			xmlData.$.id.should.equal(gameName);
		});

		it ("Game should initialize without errors", function(){

			if(gameName == "fatcat7")
			{
				game = new FatCat7Game();
				isFreeSpinGame = true;
			}
			else if(gameName == "bounty")
			{
				game = new BountyGame();
				isFreeSpinGame = true;
			}
			else if(gameName == "gummibar")
			{
				game = new GummiBarGame();
				isFreeSpinGame = false;
			}
			else if(gameName == "aprilmadness")
			{
				game = new AprilMadnessGame();
				isFreeSpinGame = true;
			}
			else if(gameName == "moneybooth")
			{
				game = new MoneyBoothGame();
				isFreeSpinGame = false;
			}
			else if(gameName == "astrologyanswers")
			{
				game = new AstrologyAnswersGame();
				isFreeSpinGame = false;
				isBothFreeSpinAndOtherBonus = true;
			}
			else if(gameName == "xtremecash")
			{
				game = new XtremeCashGame();
				isFreeSpinGame = true;
			}
			else if(gameName == "firehousefrenzy")
			{
				game = new FireHouseFrenzyGame();
				isFreeSpinGame = true;
			}
			else if(gameName == "monkeymadness")
			{
				game = new MonkeyMadnessGame();
			}
			else if(gameName == "diamondstreak")
			{
				game = new DiamondStreakGame();
				isFreeSpinGame = false;
				isBothFreeSpinAndOtherBonus = false;
			}
			else if(gameName == "paymentpanic")
			{
				game = new PaymentPanicGame();
			}
			else if(gameName == "puppycash")
			{
				game = new PuppyCashGame();
				isFreeSpinGame = false;
			}
		});

		it ("Game should import XML settings without errors", function(){

			game.importGame(xmlData);
		});
	});
}

// Spin until we run out of spins
function StartMultiGameTest(){
	describe("Multi-Game Test", function(){
		var timesSpun = 0;
		
		// Spin until we run out of spins
		it ("Should be able to run a full game without errors", function(done)
		{
			// Timeout after 0.5 seconds
			this.timeout(20000000000);
			
			//For outputting to a file
			var writableStream;
			setupWriteableStream();
			
			OutputSingleGameDataHeaders();
			
			//Game Variables
			var games = 0;
			var gameStartTime = 0;
			var gameLength = 0;
			
			//Bonus game variables
			var bonusGamesHitPerGame = 0;
			var isBonusGameOn = false;
			var bonusGameWins = [];
			
			//Payline win variables
			var paylineWins = [];
			var totalPaylines = 0;
			var totalWildPaylines = 0;
			var bigWins = 0;
			var megaWins = 0;
			var epicWins = 0;
			
			//Total Spin Variables
			var totalBaseSpins = 0;
			var totalFreeSpins = 0;
			var totalBonusSpins = 0;
			var totalScatterSpins = 0;
			
			while(games < process.env.npm_config_spins)
			{
				var spinData = null;
				var spinState = game.createState(totalSpins, totalSeconds);
				bonusGamesHitPerGame = 0;
				gameStartTime = new Date().getTime();
				bonusGameWins = [];
				
				while (spinState.spinsLeft > 0)
				{
					spinData = game.spin(spinState);
					spinState = spinData.state;
					
					//if(spinState.fsTrigger)
						//console.log("Free Triggered: " + JSON.stringify(spinData) + "\n");
					//else if(spinState.fsOn)
						//console.log("Free Spin: " + JSON.stringify(spinState) + "\n");
					//if(spinState.bonusInfo)
						//console.log("Bonus Info: " + JSON.stringify(spinState) + "\n");
					//if(spinState.scatterBonus)
					//{
						//console.log("\nBonus Info: " + JSON.stringify(spinState.scatterBonus));
						//if(spinState.scatterBonus[0].type == "Wilds")
							//console.log("\Scatter Info: " + JSON.stringify(spinState.scatterBonus));
						//console.log("Scatter Count: " + JSON.stringify(spinState.scatterBonus.length));
						//console.log("Spin Window: " + JSON.stringify(spinData.spin.window) + "\n");
					//}
					//if(spinState.pickBonus)
						//console.log("Bonus Info: " + JSON.stringify(spinState.pickBonus) + "\n");
					//if(spinState.freeMoney)
						//if(spinState.freeMoney.win > 3000000)
							//console.log("Free Money: " + JSON.stringify(spinState) + "\n");
					//if(spinState.wheelBonus)
						//if(spinState.wheelBonus.win > 3000000)
						//console.log("WheelBonus: " + JSON.stringify(spinState) + "\n");
					//if(spinState.firehouseBonus != null)
						//console.log("Fire House Bonus: " + JSON.stringify(spinState.firehouseBonus));
					
					if(isBothFreeSpinAndOtherBonus)
					{
						CountBothFreeSpinAndOtherBonusGames(spinData);
					}
					else if(isFreeSpinGame)
						CountFreeSpinsFunction(spinState);
					else
						CountBonusGames(spinData);
					
					CountPayLineWins(spinData.spin);
					
					
					//console.log("Spin State: " + JSON.stringify(spinState) + "\n");
					
					
					
					loadGameData();
					var newState = game.createState(spinData.state.spinsTotal, spinData.state.secsTotal);
					spinState.secsLeft = spinState.secsLeft;
					spinState.spinsLeft = spinState.spinsLeft;
					spinState.winTotal = spinState.winTotal
					
					//Free Spin Vars
					spinState.fsOn = spinState.fsOn;
					spinState.fsSpinsLeft = parseInt(spinState.fsSpinsLeft);
					spinState.fsWinTotal = parseInt(spinState.fsWinTotal);
					spinState.fsMxTotal = parseInt(spinState.fsMxTotal);
					spinState.fsWinTotal = parseInt(spinState.fsWinTotal);
				}
				
				OutputSingleGameData(spinData);
				//console.log("\n");
				//console.log(otherGameOutput);
				games++;
			}
			
			OutputAllGameData();
			
			writableStream.end();
			
			done();
			
			setTimeout(function(){ process.exit(0); }, 1000);
			//Functions used for analysis
			
			function loadGameData()
			{
				if(gameName == "fatcat7")
				{
					game = new FatCat7Game();
					isFreeSpinGame = true;
				}
				else if(gameName == "bounty")
				{
					game = new BountyGame();
					isFreeSpinGame = true;
				}
				else if(gameName == "gummibar")
				{
					game = new GummiBarGame();
					isFreeSpinGame = false;
				}
				else if(gameName == "aprilmadness")
				{
					game = new AprilMadnessGame();
					isFreeSpinGame = true;
				}
				else if(gameName == "moneybooth")
				{
					game = new MoneyBoothGame();
					isFreeSpinGame = false;
				}
				else if(gameName == "astrologyanswers")
				{
					game = new AstrologyAnswersGame();
					isFreeSpinGame = false;
					isBothFreeSpinAndOtherBonus = true;
				}
				
				game.importGame(xmlData);
			}
			
			function OutputSingleGameDataHeaders()
			{
				var maxBonusSpins = parseInt(xmlData.maxBonusGamesHits[0]);
				
				var csvHeader = "Game,Bonus Game Hits,Win Total,Game Length";
				
				for(var i = 0; i < maxBonusSpins; i++)
				{
					csvHeader += ", Bonus Game Score" + (i+1);
				}
				
				console.log(csvHeader);
				writableStream.write(csvHeader + " \n");
			}
			
			function OutputSingleGameData(spinData)
			{
				var maxBonusSpins = parseInt(xmlData.maxBonusGamesHits[0]);
				
				gameLength = new Date().getTime() - gameStartTime;
				var gameOutput = games + "," + bonusGamesHitPerGame + "," + spinData.state.winTotal + "," + gameLength;
				var otherGameOutput = "Game " + games + ": Bonus Games Hit: " + bonusGamesHitPerGame + " Win Total: " + spinData.state.winTotal + " Game Length: " + gameLength;
				for(var i = 0; i < maxBonusSpins; i++)
				{
					if(bonusGameWins[i] != undefined)
					{
						gameOutput += "," + bonusGameWins[i];
						otherGameOutput += " Bonus Game " + (i+1) + ": " + bonusGameWins[i];
					}
					else
					{
						gameOutput += "," + "0";
						otherGameOutput += " Bonus Game " + (i+1) + ": 0";
					}
				}
				
				console.log(gameOutput);
				writableStream.write(gameOutput + "\n");
			}
			
			function CountFreeSpinsFunction (spinState)//This checks for a free spin trigger. This counter will only work for free spin games
			{
				if(spinState.fsOn == true)
				{
					if(spinState.fsTrigger != null)//Detecting the hit of a bonus
					{
						bonusGamesHitPerGame++;
						totalBonusSpins++;
						totalBaseSpins++;
					}
					else
						totalFreeSpins++;

					if(spinState.fsSpinsLeft == 0)
					{
						//console.log("Spin Free: " + JSON.stringify(spinState));
						bonusGameWins[bonusGamesHitPerGame-1] = spinState.fsWinTotal;
					}
				}
				else
					totalBaseSpins++;
			};
			
			function CountBothFreeSpinAndOtherBonusGames(spinData)
			{
				spinsState = spinData.state;
				CountFreeSpinsFunction(spinsState);
				
				if(spinState.wheelBonus != null)//Astrology Answers
				{
					bonusGamesHitPerGame++;
					totalBonusSpins++;
					//console.log("Wheel Bonus: " + JSON.stringify(spinState.wheelBonus));
					bonusGameWins[bonusGamesHitPerGame-1] = spinState.wheelBonus.win;
				}
				else if(spinState.freeMoney != null)//Astrology Answers
				{
					bonusGamesHitPerGame++;
					totalBonusSpins++;
					//console.log("Free Money Bonus: " + JSON.stringify(spinState.freeMoney));
					bonusGameWins[bonusGamesHitPerGame-1] = spinState.freeMoney.win;
				}
			};
			
			function CountPayLineWins(spin)
			{
				if(spin.wins.results)
				{
					totalPaylines += spin.wins.results.length;
					
					for(var i = 0; i < spin.wins.results.length; i++)
					{
						if(paylineWins[spin.wins.results[i].symbol] == null || 
							paylineWins[spin.wins.results[i].symbol] == undefined)
						{
							paylineWins[spin.wins.results[i].symbol] = 1;
						}
						else
							paylineWins[spin.wins.results[i].symbol]++;
						
						if(spin.wins.results[i].wilds > 0)
							totalWildPaylines++;
						
						if(spin.wins.results[i].symbol == "S" || spin.wins.results[i].symbol == "S2" || spin.wins.results[i].symbol == "S3" || spin.wins.results[i].symbol == "S4")
							totalScatterSpins++;
					}
					
					if(spin.wins.pay >= 1500000)//Epic win
						epicWins++;
					else if(spin.wins.pay >= 1000000)
						megaWins++;
					else if(spin.wins.pay >= 500000)
						bigWins++;
				}
			}
			
			function OutputAllGameData()
			{
//				var symbols = ["P1","P2","P3","P4","P5","P6","P7","P8","P9","P10","B","BB","S","S2","S3","S4","S5"];
//				var sym = "";
//				
//				for(var ghj = 0; ghj < symbols.length; ghj++)
//				{
//					sym = symbols[ghj];
//					if(paylineWins[sym] == null || paylineWins[sym] == undefined)
//						console.log(sym + ": 0 (0%)");
//					else
//						console.log(sym + ": " + paylineWins[sym] + "(" + calcPerc(paylineWins[sym], totalPaylines) + "%)");
//				}
				
				console.log("Total Base Spins," + totalBaseSpins);
				console.log("Total Free Spins," + totalFreeSpins);
				console.log("Total Bonus Spins," + totalBonusSpins);
				console.log("Total Scatter Spins," + totalScatterSpins);
				
				console.log("Total Paylines," + totalPaylines);
				console.log("Total Wild Paylines," + totalWildPaylines);
				
				console.log("Epic wins," + epicWins);
				console.log("Mega wins," + megaWins);
				console.log("Big wins," + bigWins);
				console.log("DONE!");
				
				writableStream.write("Total Base Spins," + totalBaseSpins + "\n");
				writableStream.write("Total Free Spins," + totalFreeSpins + "\n");
				writableStream.write("Total Bonus Spins," + totalBonusSpins + "\n");
				writableStream.write("Total Scatter Spins," + totalScatterSpins + "\n");
				writableStream.write("Total Paylines," + totalPaylines + "\n");
				writableStream.write("Total Wild Paylines," + totalWildPaylines + "\n");
				writableStream.write("Epic wins," + epicWins + "\n");
				writableStream.write("Mega wins," + megaWins + "\n");
				writableStream.write("Big wins," + bigWins + "\n");
				writableStream.write("DONE!");
			}
			
			function calcPerc(got, total)
			{
				var percent = (got / total) * 100;
				percent = percent.toFixed(2);
				return percent;
			}
			
			function setupWriteableStream()
			{
				writableStream = fs.createWriteStream("./testOutputFile.txt");
				writableStream.on("error", function(err) {
				console.log("ERROR");
				//done(err);
				});
				writableStream.on("close", function(ex) {
					console.log("CLOSED");
					//done();
				});
				writableStream.on("finish", function(ex) {
					console.log("ENDED");
					//done();
				});
				writableStream.on("open", function(fd) {
					console.log("OPENED:"+fd);
				});
			}
			
			//Functions for gummibar
			function CountBonusGames(spinData)
			{
				spinsState = spinData.state;
				//console.log("Main Bonus Info: " + JSON.stringify(spinState));
				if(spinState.MainBonusInfo)//Gummibar
				{
					//console.log("SPinState: " + JSON.stringify(spinState));
					bonusGamesHitPerGame++;
					totalBonusSpins++;
					
					bonusGameWins[bonusGamesHitPerGame-1] = spinState.MainBonusInfo.win;
				}
				else if(spinState.bonusInfo)//MoneyBooth
				{
					bonusGamesHitPerGame++;
					totalBonusSpins++;

					bonusGameWins[bonusGamesHitPerGame-1] = spinState.bonusInfo.total;
				}
				else if(spinState.pickBonus)//Bankroll bandits / Monkey Madness
				{
					bonusGamesHitPerGame++;
					totalBonusSpins++;

					bonusGameWins[bonusGamesHitPerGame-1] = spinState.pickBonus.total;
				}
				totalBaseSpins++;
			};
		});
	});
}

// Run the test!
run();

