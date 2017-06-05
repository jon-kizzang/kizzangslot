/**
*	Made by The Engine Co For Kizzang
*
*	This module verifies the mySQL server setup and is meant to
*	be called on server start. If the expected server setup is
*	altered at any point then it is extremely important that the
*	template objects in this file are made to match.
*/

/** Global ***/
var staticConn;
var dynamicConn;

/*** Variables ***/
var errorMessage = "\n";
var allPassed = true;

/*
	Generates column data
*/
function generateColumn(fieldv, typev, nullv, keyv, defaultv, extrav) {

	// Handle default parameters
	if (typeof extrav === "undefined") {
		extrav = "";
		if (typeof defaultv === "undefined") {
			defaultv = null;
			if (typeof keyv === "undefined") {
				keyv = "";
				if (typeof nullv === "undefined") {
					nullv = "NO"; 
					if (typeof typev === "undefined") throw new Error ("[MySQLFormatVerification] The type must be defined in column generation!");
				}
			}
		}
	}

	var retObj = {
		Field: fieldv,
		Type: typev,
		Null: nullv,
		Key: keyv,
		Default: defaultv,
		Extra: extrav
	}

	return retObj;
}


/*
	Takes an array of functions and uses it to generate a stack that can be used
	to call functions one after another asynchronously
*/
function genAndRunQueue(functions) {

	functions.next = function(index) {

		this.shift();
		this[0](index);
	}

	functions[0](0);
}

/*
	Compares the values of two table data sets and returns the result

	If the values do not match then the function will log all of the ways they
	do not match
*/
function compareData(tableName, templatem, sqlDatam) {

	var match = true;
	var template = templatem.slice();
	var sqlData = sqlDatam.slice();

	// First check the size of the arrays
	if (template.length != sqlData.length) {
		errorMessage += "Column number mismatch in " + tableName + " | Expected: " + template.length + " Actual: " + sqlData.length + "\n";
		match = false;
	}

	// Now check the individual data
	for (var i=0; i < template.length && sqlData.length > 0; i++) {

		for (var j=0; j < sqlData.length && template.length > 0; j++) {

			// Match the Fields first, then go from there
			if (template[i].Field === sqlData[j].Field) {

				if (template[i].Type !== sqlData[j].Type) {
					errorMessage += "Type mismatch in " + tableName + " for Field " + template[i].Field + " | Expected " + template[i].Type + " Actual: " + sqlData[j].Type + "\n";
					match = false;
				}
				if (template[i].Null !== sqlData[j].Null) {
					errorMessage += "Null mismatch in " + tableName + " for Field " + template[i].Field + " | Expected " + template[i].Null + " Actual: " + sqlData[j].Null + "\n";
					match = false;
				}
				if (template[i].Key !== sqlData[j].Key) {
					errorMessage += "Key mismatch in " + tableName + " for Field " + template[i].Field + " | Expected " + template[i].Key + " Actual: " + sqlData[j].Key + "\n";
					match = false;
				}
				if (template[i].Default !== sqlData[j].Default) {
					errorMessage += "Default mismatch in " + tableName + " for Field " + template[i].Field + " | Expected " + template[i].Default + " Actual: " + sqlData[j].Default + "\n";
					match = false;
				}
				if (template[i].Extra !== sqlData[j].Extra) {
					errorMessage += "Extra mismatch in " + tableName + " for Field " + template[i].Field + " | Expected " + template[i].Extra + " Actual: " + sqlData[j].Extra + "\n";
					match = false;
				}

				template.splice(i--, 1);
				sqlData.splice(j, 1);
				break;
			}
		}
	}

	// If there are still columns left to find, log what fields were not found
	if (template.length > 0) {

		match = false;
		for (var i=0; i<template.length; i++) {

			errorMessage += "Column not found in " + tableName + " | Expected Column with Field: " + template[i].Field + "\n";
		}
	}

	// There should not be any fields remaining in the sql data
	if (sqlData.length > 0) {

		match = false;
		for (var i=0; i<sqlData.length; i++) {

			errorMessage += "Unexpected column found in " + tableName + " | Column Field: " + sqlData[i].Field + "\n";
		}
	} 

	return match;
}

/*
	Takes create table data and parses the data related to the creation of partitions so it can
	be smartly checked against a template
*/
parsePartitionData = function(createData) {

	// First make sure we are using partitions at all
	if (createData.indexOf("PARTITION") === -1) return null;

	var dataObj = {};

	// Get the data that pertains to partitions, the rest can be ignored here
	var pInfo = createData.slice(createData.indexOf("/*")+2, createData.indexOf("*/")).split("\n");

	// Handle the main partition function call
	if (pInfo[0].indexOf('!') === -1) dataObj.version = null;
	else dataObj.version = pInfo[0].slice(pInfo[0].indexOf("!")+1, pInfo[0].indexOf(" "));

	dataObj.command = pInfo[0].slice(pInfo[0].indexOf("PARTITION"), pInfo[0].indexOf("(")).trim();
	dataObj.parameters = pInfo[0].slice(pInfo[0].indexOf("(")+1, pInfo[0].lastIndexOf(")")).trim();

	// Move on to the partition function body
	pInfo.shift(); // We don't need the function call in this array anymore

	// Normalize the strings, removing the initial and final parentheses, commas, and extra white space
	pInfo[0] = pInfo[0].slice(pInfo[0].indexOf("(")+1);
	pInfo[pInfo.length-1] = pInfo[pInfo.length-1].slice(0, pInfo[pInfo.length-1].lastIndexOf(")"));

	for (var i in pInfo) {

		if(pInfo[i].indexOf(",") !== -1) pInfo[i] = pInfo[i].slice(0, pInfo.lastIndexOf(","));
		pInfo[i] = pInfo[i].trim();
	}

	dataObj.functionBody = pInfo;

	return dataObj;
}

/*
	Compares parsed partition data with a provided template
*/
function comparePartitionData(tableName, templatem, sqlData) {

	var match = true;
	var template = Object.create(templatem);
	
	// If there is no partition data at all
	if (!sqlData) {
		
		errorMessage += "Paritition missing in " + tableName + " | Expected: " + template.command + "\n";
		return false;
	}

	// Check the main function call information
	if (template.version) {

		if (template.version !== sqlData.version) {

			match = false;
			errorMessage += "Version mismatch in " + tableName + " partition data | Expected: " + template.version + " Actual: " + sqlData.version + "\n";
		}
	} else {

		// If no version was defined in the template, there shouldn't be a version in the sql data
		if (sqlData.version) {

			match = false;
			errorMessage += "Unexpected version found in " + tableName + " partition data | Found version: " + sqlData.version + "\n";
		}
	}

	if (template.command !== sqlData.command) {

		match = false;
		errorMessage += "Partition command mismatch in " + tableName + " | Expected: " + template.command + " Actual: " + sqlData.command + "\n";
	}

	if (template.parameters !== sqlData.parameters) {

		match = false;
		errorMessage += "Partition command parameters mismatch in " + tableName + " | Expected: " + template.parameters + " Actual: " + sqlData.parameters + "\n";
	}

	// We are going to be messing with the template array, so we need to set a new one as to not mess with the original
	template.functionBody = template.functionBody.slice();

	// Now we need to check the the command body
	if (template.functionBody.length !== sqlData.functionBody.length) {

		match = false;
		errorMessage += "Partition function body length mismatch in " + tableName + " | Expected: " + template.functionBody.length + " Actual: " + sqlData.functionBody.length + "\n";
	}

	for (var i=0; i<template.functionBody.length; i++) {

		if (template.functionBody[i] != sqlData.functionBody[i]) {

			match = false;
			errorMessage += "Partition function body line mismatch in " + tableName + " at line " + i + " | Expected: " + templatem.functionBody[i] + " Actual: " + sqlData.functionBody[i] + "\n";
		}
	}

	if (template.functionBody.length < sqlData.functionBody.length) {

		for (var i=template.functionBody.length; i<sqlData.functionBody.length; i++) {

			errorMessage += "Unexpected partition function line in " + tableName + " at line " + i + " | Found: " + sqlData.functionBody[i] + "\n";
		}
	}

	return match;
}

var slotTableData = [
	generateColumn("ID", "int(10) unsigned", "NO", "PRI", null, "auto_increment"),
	generateColumn("Host", "varchar(200)"),
	generateColumn("Port", "int(10) unsigned"),
	generateColumn("CryptoOn", "tinyint(3) unsigned"),
	generateColumn("CryptoKey", "varchar(100)"),
	generateColumn("Debug", "tinyint(3) unsigned"),
	generateColumn("MathList", "text"),
	generateColumn("MaxConnections", "int(10) unsigned"),
	generateColumn("StartDate", "datetime"),
]

checkSlotServer = function () {

	thisFunc = this;

	staticConn.query("DESCRIBE SlotServer", function(err, data) {

		if (err) {
			errorMessage += "SlotServer table check encountered an error | Error: " + err + "\n";
			thisFunc.next();
			return;
		}

		if(!compareData("SlotServer", slotTableData, data)) {

			console.warn("SlotServer table check failed");
			allPassed = false;
		} else console.log("SlotServer table check completed");

		thisFunc.next();
	});
}

var playersData = [
	generateColumn("PlayerID", "bigint(20) unsigned", "NO", "PRI"),
	generateColumn("TournamentID", "int(10) unsigned"),
	generateColumn("Token", "char(40)", "YES", "UNI"),
	generateColumn("SessionID", "bigint(20) unsigned", "YES"),
	generateColumn("TournamentList", "text", "YES"),
	generateColumn("ScreenName", "char(25)", "NO"),
	generateColumn("FacebookID", "varchar(20)", "YES")
]

checkPlayers = function () {

	thisFunc = this;

	staticConn.query("DESCRIBE Players", function(err, data) {

		if (err) {
			errorMessage += "Players table check encountered an error | Error: " + err + "\n";
			thisFunc.next();
			return;
		}

		if(!compareData("Players", playersData, data)) {

			console.warn("Players table check failed");
			allPassed = false;
		} else console.log("Players table check completed");

		thisFunc.next();
	})
}

var slotGameData = [
	generateColumn("ID", "int(10) unsigned", "NO", "PRI", null, "auto_increment"),
	generateColumn("Name", "varchar(100)"),
	generateColumn("Theme", "varchar(50)"),
	generateColumn("Math", "varchar(50)"),
	generateColumn("StartTime", "time"),
	generateColumn("EndTime", "time"),
	generateColumn("SpinsTotal", "smallint(5) unsigned"),
	generateColumn("SecsTotal", "mediumint(8) unsigned"),
	generateColumn("CreateDate", "datetime")
]

checkSlotGame = function () {

	thisFunc = this;

	staticConn.query("DESCRIBE SlotGame", function(err, data) {

		if (err) {
			errorMessage += "SlotGame table check encountered an error | Error: " + err + "\n";
			thisFunc.next();
			return;
		}

		if(!compareData("SlotGame", slotGameData, data)) {

			console.warn("SlotGame table check failed");
			allPassed = false;
		} else console.log("SlotGame table check completed");

		thisFunc.next();
	})
}

var slotTournamentData = [

	generateColumn("ID", "int(10) unsigned", "NO", "PRI", null, "auto_increment"),
	generateColumn("StartDate", "datetime", "YES"),
	generateColumn("EndDate", "datetime", "YES"),
	generateColumn("PrizeList", "text", "YES"),        
	generateColumn("GameIDs", "set('angrychefs','bankrollbandits','butterflytreasures','underseaworld','romancingriches','underseaworld2','oakinthekitchen','crusadersquest','mummysrevenge','ghosttreasures','penguinriches','bounty','christmas','happynewyear')", "NO"),
	generateColumn("type", "enum('Daily','Weekly','Monthly','HalfDay')", "NO", "", "Daily"),
	generateColumn("Title", "varchar(50)", "YES")


]

checkSlotTournament = function () {

	thisFunc = this;

	staticConn.query("DESCRIBE SlotTournament", function(err, data) {

		if (err) {
			errorMessage += "SlotTournament table check encountered an error | Error: " + err + "\n";
			thisFunc.next();
			return;
		}

		if(!compareData("SlotTournament", slotTournamentData, data)) {

			console.warn("SlotTournament table check failed");
			allPassed = false;
		} else console.log("SlotTournament table check completed");

		thisFunc.next();
	})
}

/*
	Doesn't actually verify any tables, but gets the currently active tournaments so that can be passed
	along to the Session and Log table checks. Historical Session and Log tables may not match the expected
	schema, but they are not being actively used so they should be ignored.
*/
getActiveTournaments = function() {

	thisFunc = this;

	staticConn.query("SELECT ID FROM SlotTournament WHERE EndDate>NOW()", function(err, data) {

		// Extract the active tournament IDs and send them along
		var activeTournaments =  {};

		if (err) {

			// An error here is bad
			console.error ("Encountered an error attempting to determine active tournaments | Error: " + err);
			thisFunc.next(activeTournaments);
			return;
		}

		if (data.length == 0) {

			// No active tournaments?
			console.warn ("No active tournaments found");
			thisFunc.next(activeTournaments);
			return;
		}

		for (var i in data) {

			// Let's be clever with our object to improve efficiency
			activeTournaments[parseInt(data[i].ID)] = true;
		}

		thisFunc.next(activeTournaments);
	});
}

var slotSessionData = [
	generateColumn("SessionID", "bigint(20) unsigned", "NO", "PRI", null, "auto_increment"),
	generateColumn("Token", "char(40)", "YES", "MUL"),
	generateColumn("PlayerID", "bigint(20) unsigned", "YES", "MUL"),
	generateColumn("GameID", "int(10) unsigned", "YES"),
	generateColumn("StartTime", "bigint(20)")
]

var slotSessionPartitionData = {
	version: '50100',
 	command: 'PARTITION BY RANGE',
 	parameters: 'SessionID MOD 24',
 	functionBody: [
	     'PARTITION p0 VALUES LESS THAN (1) ENGINE = InnoDB',
	     'PARTITION p1 VALUES LESS THAN (2) ENGINE = InnoDB',
	     'PARTITION p2 VALUES LESS THAN (3) ENGINE = InnoDB',
	     'PARTITION p3 VALUES LESS THAN (4) ENGINE = InnoDB',
	     'PARTITION p4 VALUES LESS THAN (5) ENGINE = InnoDB',
	     'PARTITION p5 VALUES LESS THAN (6) ENGINE = InnoDB',
	     'PARTITION p6 VALUES LESS THAN (7) ENGINE = InnoDB',
	     'PARTITION p7 VALUES LESS THAN (8) ENGINE = InnoDB',
	     'PARTITION p8 VALUES LESS THAN (9) ENGINE = InnoDB',
	     'PARTITION p9 VALUES LESS THAN (10) ENGINE = InnoDB',
	     'PARTITION p10 VALUES LESS THAN (11) ENGINE = InnoDB',
	     'PARTITION p11 VALUES LESS THAN (12) ENGINE = InnoDB',
	     'PARTITION p12 VALUES LESS THAN (13) ENGINE = InnoDB',
	     'PARTITION p13 VALUES LESS THAN (14) ENGINE = InnoDB',
	     'PARTITION p14 VALUES LESS THAN (15) ENGINE = InnoDB',
	     'PARTITION p15 VALUES LESS THAN (16) ENGINE = InnoDB',
	     'PARTITION p16 VALUES LESS THAN (17) ENGINE = InnoDB',
	     'PARTITION p17 VALUES LESS THAN (18) ENGINE = InnoDB',
	     'PARTITION p18 VALUES LESS THAN (19) ENGINE = InnoDB',
	     'PARTITION p19 VALUES LESS THAN (20) ENGINE = InnoDB',
	     'PARTITION p20 VALUES LESS THAN (21) ENGINE = InnoDB',
	     'PARTITION p21 VALUES LESS THAN (22) ENGINE = InnoDB',
	     'PARTITION p22 VALUES LESS THAN (23) ENGINE = InnoDB',
	     'PARTITION p23 VALUES LESS THAN (24) ENGINE = InnoDB'
     ]}

checkSlotSessions = function (activeTournaments) {

	thisFunc = this;

	// First we need to determine how many slot sessions there actually are, and what they are called
	staticConn.query("SHOW Tables", function(err, data) {

		// We can't be sure what the database is called, and it doesn't matter, so we have to be clever
		sessionList = [];

		for( var i in data ) {
			for( var j in data[i] ) { // Still O*n because data[i] should only ever have 1 element
				if(data[i].hasOwnProperty(j) && data[i][j].indexOf("Session") != -1) {

					// We found a session table, now make sure that it is active
					if (activeTournaments[parseInt(data[i][j].slice(data[i][j].indexOf('_')+1))]) sessionList.push(data[i][j]);
				}
			}
		}

		if (sessionList.length == 0) {

			// If we have no sessions then move on
			errorMessage += "No Slot Session Tables found \n";

			thisFunc.next();
			return;
		}

		// Generate a queue for sessions
		var functions = []

		for (i in sessionList){ // For each session found...
			functions.push(function(index){ // Add a new function to the function list...

				thisInnerFunc = this;

				staticConn.query("DESCRIBE " + sessionList[index], function(err, data) { // That gets mySQL data...

					if (err) {
						errorMessage += sessionList[index] + " table check encountered an error | Error: " + err + "\n";
						thisInnerFunc.next(++index);
						return;
					}

					if(!compareData(sessionList[index], slotSessionData, data)) { // compares it with the template...

						console.warn(sessionList[index] + " table check failed");
						allPassed = false;
					} else console.log(sessionList[index] + " table check completed");

					staticConn.query("SHOW CREATE TABLE " + sessionList[index], function(err, data) { // gets the Partition formation data...

						if (!comparePartitionData(sessionList[index], slotSessionPartitionData, parsePartitionData(data[0]["Create Table"]))) { // and compares the template

							console.warn(sessionList[index] + " partition check failed");
							allPassed = false;
						} else console.log(sessionList[index] + " partition check completed");

						thisInnerFunc.next(++index);
					})
				})
			});
		}

		functions.push(function(){ // Also add an ending function, that will take us to the next operation

			thisFunc.next(activeTournaments);
		})

		genAndRunQueue(functions);
	})
}

var slotLogData = [
	generateColumn("SessionID", "bigint(20) unsigned", "NO", "PRI"),
	generateColumn("Gen", "int(10) unsigned", "NO", "PRI"),
	generateColumn("GameData", "text", "YES"),
	generateColumn("SpinsLeft", "smallint(5) unsigned"),
	generateColumn("SpinsTotal", "smallint(5) unsigned"),
	generateColumn("SecsLeft", "smallint(5) unsigned"),
	generateColumn("SecsTotal", "smallint(5) unsigned"),
	generateColumn("WinCurrent", "int(10) unsigned"),
	generateColumn("WinTotal", "bigint(20) unsigned"),
	generateColumn("CreateTime", "bigint(20) unsigned", "NO", "PRI"),
	generateColumn("ReelOffsets", "binary(11)"),
	generateColumn("FSTriggers", "binary(13)", "YES")
]

var slotLogPartitionData = { 
	version: '50100',
  	command: 'PARTITION BY RANGE',
  	parameters: '( CreateTime DIV 3600000 ) MOD 24',
  	functionBody: [
	    'PARTITION p0 VALUES LESS THAN (1) ENGINE = InnoDB',
	    'PARTITION p1 VALUES LESS THAN (2) ENGINE = InnoDB',
	    'PARTITION p2 VALUES LESS THAN (3) ENGINE = InnoDB',
	    'PARTITION p3 VALUES LESS THAN (4) ENGINE = InnoDB',
	    'PARTITION p4 VALUES LESS THAN (5) ENGINE = InnoDB',
	    'PARTITION p5 VALUES LESS THAN (6) ENGINE = InnoDB',
	    'PARTITION p6 VALUES LESS THAN (7) ENGINE = InnoDB',
	    'PARTITION p7 VALUES LESS THAN (8) ENGINE = InnoDB',
	    'PARTITION p8 VALUES LESS THAN (9) ENGINE = InnoDB',
	    'PARTITION p9 VALUES LESS THAN (10) ENGINE = InnoDB',
	    'PARTITION p10 VALUES LESS THAN (11) ENGINE = InnoDB',
	    'PARTITION p11 VALUES LESS THAN (12) ENGINE = InnoDB',
	    'PARTITION p12 VALUES LESS THAN (13) ENGINE = InnoDB',
	    'PARTITION p13 VALUES LESS THAN (14) ENGINE = InnoDB',
	    'PARTITION p14 VALUES LESS THAN (15) ENGINE = InnoDB',
	    'PARTITION p15 VALUES LESS THAN (16) ENGINE = InnoDB',
	    'PARTITION p16 VALUES LESS THAN (17) ENGINE = InnoDB',
	    'PARTITION p17 VALUES LESS THAN (18) ENGINE = InnoDB',
	    'PARTITION p18 VALUES LESS THAN (19) ENGINE = InnoDB',
	    'PARTITION p19 VALUES LESS THAN (20) ENGINE = InnoDB',
	    'PARTITION p20 VALUES LESS THAN (21) ENGINE = InnoDB',
	    'PARTITION p21 VALUES LESS THAN (22) ENGINE = InnoDB',
	    'PARTITION p22 VALUES LESS THAN (23) ENGINE = InnoDB',
	    'PARTITION p23 VALUES LESS THAN (24) ENGINE = InnoDB'
     ]}

checkSlotLogs = function (activeTournaments) {

	thisFunc = this;

	// First we need to determine how many slot sessions there actually are, and what they are called
	staticConn.query("SHOW Tables", function(err, data) {

		// We can't be sure what the database is called, and it doesn't matter, so we have to be clever
		logList = [];

		for( var i in data ) {
			for( var j in data[i] ) {
				if(data[i].hasOwnProperty(j) && data[i][j].indexOf("Log") != -1) {

					// Emit a warning if we found "SlotLog" but don't do anything else with it
					if (data[i][j] === "SlotLog") {

						console.log ("Table 'SlotLog' found. Ignoring...");
						continue;
					}

					// We found a session table, now make sure that it is active
					if (activeTournaments[parseInt(data[i][j].slice(data[i][j].indexOf('_')+1))]) logList.push(data[i][j]);
				}
			}
		}

		if (logList.length == 0) {

			// If we have no sessions then move on
			errorMessage += "No Slot Log Tables found \n";

			thisFunc.next();
			return;
		}

		// Generate a queue for sessions
		var functions = []

		for (i in logList){ // For each session found...
			functions.push(function(index){ // Add a new function to the function list...

				thisInnerFunc = this;

				dynamicConn.query("DESCRIBE " + logList[index], function(err, data) { // That gets mySQL data...

					if (err) {
						errorMessage += logList[index] + " table check encountered an error | Error: " + err + "\n";
						thisInnerFunc.next(++index);
						return;
					}

					if(!compareData(logList[index], slotLogData, data)) { // compares it with the template...

						console.warn(logList[index] + " table check failed");
						allPassed = false;
					} else console.log(logList[index] + " table check completed");

					dynamicConn.query("SHOW CREATE TABLE " + logList[index], function(err, data) { // gets the Partition formation data...

						if (!comparePartitionData(logList[index], slotLogPartitionData, parsePartitionData(data[0]["Create Table"]))) { // and compares the template

							console.warn(logList[index] + " partition check failed");
							allPassed = false;
						} else console.log(logList[index] + " partition check completed");

						thisInnerFunc.next(++index);
					})
				})
			});
		}

		functions.push(function(){ // Also add an ending function, that will take us to the next operation

			thisFunc.next();
		})

		genAndRunQueue(functions);
	})
}

finish = function () {

	if (!allPassed) console.error(errorMessage);

	this.next();
}

/*
	Checks every required MySQL table's description to ensure that the
	format of each table matches expectations. If any of the mySQL tables
	do not match expectations, an error will be thrown with information on
	all mismatching aspects.

	This operation will NOT end early if an error is detected, it will always
	do a full test pass every time it is called.

	It is expected that this function will be called on server startup
*/
exports.checkMySQL = function (sConn, dConn, complete) {

	staticConn = sConn;
	dynamicConn = dConn;

	genAndRunQueue([
		checkSlotServer,
		checkPlayers,
		checkSlotGame,
		checkSlotTournament,
		getActiveTournaments,
		checkSlotSessions,
		checkSlotLogs,
		finish,
		complete
	]);
}
