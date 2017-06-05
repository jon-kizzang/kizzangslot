/* global __dirname */
//Requrements
var fs = require ('fs')
var http = require ('http')
var xml2js = require ('xml2js')
var urlencoder = require ('form-urlencoded')

//Constants representing different Game IDs
var BOUNTY_ID = 11;
var PENGUIN_ID = 10;
var UNDERSEA_ID = 4;
var UNDERSEA_2_ID = 9;
var OAK_ID = 7;
var CRUSADER_ID = 8;
var FAT_CAT_ID = 12;
var MONEY_BOOTH_ID = 13;

//Get the port from the slotserver.xml file
var serverPort = 1337;

var parser = new xml2js.Parser ({trim:true});

/** Settings Variables **/
var numberOfGames = 1;

/** Global Veriables **/
var gamesRun = 0;
var xmlData = {};

/** "Constants" **/
var FBID = "3036166739340211762";

function run(){

	describe("HTTPTest", function(){

		initialize();
		lobbyList();
		registering();
		spinAndRankMatching();
		gameInAssets();
		nameChange();
	});
}

function initialize(){
	describe("Initialization", function(){
		it ("Should initialize without errors", function(done){

			this.timeout(0);
			var xmlString = fs.readFileSync(__dirname + '/../slotserver.xml').toString();

			parser.parseString (xmlString, function (err, result){

				if (err) throw new Error("Could not read XML file: " + err)
				
				xmlData = result;
				
				serverPort = parseInt(result.configuration.port[0]);

				done();
			});
		});
	});
}

function lobbyList() {
	describe("Lobby List", function() {
		
		var lobbyData = {};
		
		it ("Should be able to get data from the `lobby` endpoint", function(done) {
			generateRequest("/command/lobby", {}, function(resData){

				if (resData.ok != 1) throw new Error(resData.msg);

				lobbyData = resData.response;

				done();
			});
		});
		
		it ("Times should be in timezone defined in settings xml", function() {
		
			for (var i=0; i < lobbyData.tournaments.length; i++) {
				if (lobbyData.tournaments[i].startTime.indexOf(xmlData.configuration.displayTime[0].timezone[0]) == -1)
					throw new Error("Lobby Data times not in correct timezone! Expected TZ: %s, Time String: %s", xmlData.configuration.displayTime[0].timezone[0], lobbyData.tournaments[i].startTime);
				
				if (lobbyData.tournaments[i].endTime.indexOf(xmlData.configuration.displayTime[0].timezone[0]) == -1)
					throw new Error("Lobby Data times not in correct timezone! Expected TZ: %s, Time String: %s", xmlData.configuration.displayTime[0].timezone[0], lobbyData.tournaments[i].endTime);
			}
		});
	});
}

function registering(){
	describe("Registration", function(){
		it ("Registration should succeed", function(done){

			this.timeout(0);

			var reqData = {

				data: JSON.stringify({ tournamentId: 1, screenName: "Name1", playerId: 1, gameId: 1, appToken: "Tok", apiKey: "key" })
			};

			console.log("Registering ID: 1");

			generateRequest("/bcommand/regToken", reqData, function(resData){

				if (resData.ok != 1) throw new Error(resData.msg);

				console.log ("Register ID 1 complete");

				done();
			});
		});

		it ("Player check should result a positive", function(done){

			this.timeout(0);

			var reqData = {

				data: JSON.stringify({ playerId: 1 })
			};

			console.log ("Checking player 1");

			generateRequest("/command/checkPlayer", reqData, function(resData){

				if (resData.ok != 1) throw new Error(resData.msg);

				resData.response.inGame.should.equal(true);
				done();
			});
		});
	});
}

function spinAndRankMatching(){
	describe("Spin and Rank matching", function(){
		
		describe("Money Booth", function(){
			it ("Final spin score and rank score should match over " + numberOfGames + " games", function(done){
				this.timeout(0);
				gamesRun = 0;

				for (var i=0; i<numberOfGames; i++){
					spinAndRankMatching_register(MONEY_BOOTH_ID, i+1, function(){

						done();
					});
				}
			});
		});
		
		describe("Fat Cat 7s", function(){
			it ("Final spin score and rank score should match over " + numberOfGames + " games", function(done){
				this.timeout(0);
				gamesRun = 0;

				for (var i=0; i<numberOfGames; i++){
					spinAndRankMatching_register(FAT_CAT_ID, i+1, function(){

						done();
					});
				}
			});
		});
		
		describe("Bounty", function(){
			it ("Final spin score and rank score should match over " + numberOfGames + " games", function(done){
				this.timeout(0);
				gamesRun = 0;

				for (var i=0; i<numberOfGames; i++){
					spinAndRankMatching_register(BOUNTY_ID, i+1, function(){

						done();
					});
				}
			});
		});
		
		describe("Penguin Riches", function(){
			it ("Final spin score and rank score should match over " + numberOfGames + " games", function(done){
				this.timeout(0);
				gamesRun = 0;

				for (var i=0; i<numberOfGames; i++){
					spinAndRankMatching_register(PENGUIN_ID, i+1, function(){

						done();
					});
				}
			});
		});
		
		describe("Undersea World", function(){
			it ("Final spin score and rank score should match over " + numberOfGames + " games", function(done){
				this.timeout(0);
				gamesRun = 0;

				for (var i=0; i<numberOfGames; i++){
					spinAndRankMatching_register(UNDERSEA_ID, i+1, function(){

						done();
					});
				}
			});
		});

		describe("Undersea World 2", function(){
			it ("Final spin score and rank score should match over " + numberOfGames + " games", function(done){
				this.timeout(0);
				gamesRun = 0;

				for (var i=0; i<numberOfGames; i++){
					spinAndRankMatching_register(UNDERSEA_2_ID, i+1, function(){

						done();
					});
				}
			});
		});
		
		describe("Oak in the Kitchen", function(){
			it ("Final spin score and rank score should match over " + numberOfGames + " games", function(done){
				this.timeout(0);
				gamesRun = 0;

				for (var i=0; i<numberOfGames; i++){
					spinAndRankMatching_register(OAK_ID, i+1, function(){

						done();
					});
				}
			});
		});
		
		describe("Crusader's Quest", function(){
			it ("Final spin score and rank score should match over " + numberOfGames + " games", function(done){
				this.timeout(0);
				gamesRun = 0;

				for (var i=0; i<numberOfGames; i++){
					spinAndRankMatching_register(CRUSADER_ID, i+1, function(){

						done();
					});
				}
			});
		});
	});
}

function spinAndRankMatching_register (gameId, playerId, done){

	if (gamesRun >= numberOfGames) return;

	var reqData = {

		data: JSON.stringify({ tournamentId: 1, screenName: "Name1", playerId: playerId, gameId: gameId, appToken: "Tok", apiKey: "key" })
	};

	console.log("Registering ID: " + playerId);

	generateRequest("/bcommand/regToken", reqData, function(resData){

		if (resData.ok != 1) throw new Error(resData.msg);

		console.log ("Register ID " + playerId + " complete");

		spinAndRankMatching_spin(resData.response.playToken, playerId, function(){

			done();
		}); 
	});
}

function spinAndRankMatching_spin (token, id, done){

	var reqData = {

		data: JSON.stringify({ playerToken: token, appToken: "Token", apiKey: "Ke" })
	};

	generateRequest("/command/spin", reqData, function(resData){

		if (resData.ok != 1){

			// If we are out of time, skip checking the ranking
			if (resData.msg.indexOf("out-of-time") != -1){

				console.log ("Games run " + ++gamesRun + " ID " + id + " ran out of time");
				if (gamesRun >= numberOfGames) done();

			} else {

				throw new Error(resData.msg);
			}
		} else {

			if (resData.response.state.spinsLeft > 0){

				// If there are spins left, keep going down
				spinAndRankMatching_spin(token, id, done);
			} else {

				spinAndRankMatching_rank(id, resData.response.state.winTotal, function(){

					done();
				});
			}
		}
	});
}

function spinAndRankMatching_rank(id, score, done){

	var reqData = {

		data: JSON.stringify({ slotPlayerId: id })
	};

	generateRequest("/command/rank", reqData, function(resData){

		if (resData.ok != 1) throw new Error(resData.msg);

		// This is the check!
		parseInt(score).should.equal(parseInt(resData.response.winTotal));

		// Log that the game is done
		console.log ("Games run: " + ++gamesRun + " finished ID " + id);

		// Get us out of stack hell once we finish all the games we want to do
		if (gamesRun >= numberOfGames) done();
	});

}

function gameInAssets(){
	describe("Games In Assets", function(){
		it ("Should get assets for Undersea World 2", function(done){

			var reqData = {

				data: JSON.stringify({ gameId: 9 }) // The ID for Undersea World 2 is 9
			};

			generateRequest("/command/assets", reqData, function(resData){

				if (resData.ok != 1){

					throw new Error(resData.msg);
				} else
					done();
			});
		});
	});
}

function nameChange(){
	describe("Name / Facebook ID Changing", function(){
		it ("Should be able to change a player's name", function(done) {

			this.timeout(0);
			nameChange_checkName("FirstName", function(){ nameChange_checkName("SecondName", done); });
		});

		it ("Should be able to change a player's Facebook ID", function(done) {

			this.timeout(0);
			nameChange_checkFB(1, function(){ nameChange_checkFB(2, done); });
		});

		it ("Providing no Name or FacebookID should NOT change data", function(done) {

			this.timeout(0);
			var reqData = {

				data: JSON.stringify({ tournamentId: 1, playerId: 1, gameId: 1, appToken: "Tok", apiKey: "key" })
			};

			console.log("Registering without providing name or facebook information");

			generateRequest("/bcommand/regToken", reqData, function(resData) {

				if (resData.ok != 1) throw new Error(resData.msg);

				// No matter what the name was before, the ID 1 should match "FirstName"
				for (var i in resData.response.neighbors.near) {

					if (resData.response.neighbors.near[i].PlayerID == '1') {

						resData.response.neighbors.near[i].ScreenName.should.equal("SecondName");

						if (resData.response.neighbors.near[i].FacebookID)
							resData.response.neighbors.near[i].FacebookID.should.equal("2");
					}
				}

				done();
			});
		});
		
		it ("Should be able to change a facebook ID from null", function(done) {
			
			this.timeout(0);
			nameChange_findNullFB(2, done);
		});
	});
}

function nameChange_checkName(name, done) {
	var reqData = {

		data: JSON.stringify({ tournamentId: 1, screenName: name, playerId: 1, gameId: 1, appToken: "Tok", apiKey: "key" })
	};

	console.log("Registering ID with name: " + name);

	generateRequest("/bcommand/regToken", reqData, function(resData) {

		if (resData.ok != 1) throw new Error(resData.msg);

		// No matter what the name was before, the ID 1 should match "FirstName"
		for (var i in resData.response.neighbors.near) {

			if (resData.response.neighbors.near[i].PlayerID == '1')
				resData.response.neighbors.near[i].ScreenName.should.equal(name);
		}

		done();
	});
}

function nameChange_checkFB(id, done) {
	var reqData = {

		data: JSON.stringify({ tournamentId: 1, screenName: "SecondName", fbId: id, playerId: 1, gameId: 1, appToken: "Tok", apiKey: "key" })
	};

	console.log("Registering ID with FacebookID: " + id);

	generateRequest("/bcommand/regToken", reqData, function(resData) {

		if (resData.ok != 1) throw new Error(resData.msg);

		// No matter what the name was before, the ID 1 should match "FirstName"
		for (var i in resData.response.neighbors.near) {

			if (resData.response.neighbors.near[i].PlayerID == '1' && resData.response.neighbors.near[i].FacebookID)
				resData.response.neighbors.near[i].FacebookID.should.equal(id.toString());
		}

		done();
	});
}

function nameChange_findNullFB(id, done) {
	
	var reqData = {

		data: JSON.stringify({ tournamentId: 1, screenName: "name", playerId: id, gameId: 1, appToken: "Tok", apiKey: "key" })
	};

	console.log("Checking ID " + id + " for null FB ID");

	generateRequest("/bcommand/regToken", reqData, function(resData) {

		if (resData.ok != 1) throw new Error(resData.msg);

		// Find this player's facebook data
		for (var i in resData.response.neighbors.near) {
			
			if (resData.response.neighbors.near[i].PlayerID == id) {

				if (!resData.response.neighbors.near[i].FacebookID)
					nameChange_changeFBFromNull(id, done);				
				else
					nameChange_findNullFB(++id, done);
			}
		}
	});
}

function nameChange_changeFBFromNull(id, done) {
	
	var reqData = {

		data: JSON.stringify({ tournamentId: 1, screenName: "name", fbId: FBID, playerId: id, gameId: 1, appToken: "Tok", apiKey: "key" })
	};

	console.log("Registering ID " + id + " with FacebookID");

	generateRequest("/bcommand/regToken", reqData, function(resData) {

		if (resData.ok != 1) throw new Error(resData.msg);

		// The Facebook ID should no longer be null
		for (var i in resData.response.neighbors.near) {

			if (resData.response.neighbors.near[i].PlayerID == id)
				resData.response.neighbors.near[i].FacebookID.should.equal(FBID);
		}

		done();
	});
}

run();

function generateRequest(path, reqData, callback){

	var options = {
		port: serverPort,
		path: path,
		method: "POST",
		headers: { 'content-type': 'application/x-www-form-urlencoded' }
	};

	// A basic http request that returns the response
	var req = http.request(options, function (response){

		var dataHold = "";

		response.on('data', function (data){

			dataHold += data;
		});

		response.on('end', function (){

			var resData = {};

			try{

				resData = JSON.parse(dataHold);
			} catch(err) {

				// If we caught a "server-too-busy" error, try again and log the error
				if (dataHold == "server-too-busy"){
					console.log("'server-too-busy' recieved, retrying...");

					generateRequest(path, reqData, callback);
				} else {
					throw new Error("JSON Parse Error. Bad JSON: " + dataHold);
				}
			}

			callback(resData);
		});
	});

	req.on('error', function (error){

		throw new Error("problem with request" + error.message);
	});

	req.write(urlencoder.encode(reqData));
	req.end();
}
