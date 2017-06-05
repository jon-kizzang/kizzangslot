var badTableCheck = require("./badTableCheck.js");

var SQL_ATTEMPTS = 6 //How many attempts should be made to register data to SQL
var SQL_WAIT_TIME = 5000 //How much time (in ms) to wait before re-trying a SQL log

var MEM_ATTEMPTS = 6 //How many attempts should be made to register data to memcached
var MEM_WAIT_TIME = 5000 //How much time (in ms) to wait before re-trying a memcached log

var REDIS_ATTEMPTS = 6 //How many attempts should be made to register data to redis
var REDIS_WAIT_TIME = 5000 //How much time (in ms) to wait before re-trying a redis log

/**
 * Write data to SQL, recursing up to SQL_ATTEMPTS times
 */
function writeToSQL(sqlClient, sql, args, tryCount, callback) {
	sqlClient.query(sql, args, function(err, result) {
		if (err) {
			if (tryCount < SQL_ATTEMPTS) {
				
				console.warn("Attempt " + tryCount + " for SQL write failed, retrying in " + SQL_WAIT_TIME + "ms", err);
				console.warn(sql);

				setTimeout(function(){

					writeToSQL(sqlClient, sql, args, ++tryCount, callback) 
				}, SQL_WAIT_TIME);
			} else {
				
				// We failed, call the failure state
				callback(err, null);
			}
		} else {
			
			// We succeeded! Call the success state!
			callback(null, result);
		}
	});
}

/**
 * Write data to Memcached, recursing up to MEM_ATTEMPTS times
 */
function writeToMC(mcClient, mcKey, argsBuffer, other, tryCount, callback) {
	mcClient.set(mcKey, argsBuffer, other, function(err, result) {
		if (err) {
			if (tryCount < MEM_ATTEMPTS) {

				console.warn("Attempt " + tryCount + " for Memcached write failed, retrying in " + MEM_WAIT_TIME + "ms", err);

				setTimeout(function(){

					writeToMC(mcClient, mcKey, argsBuffer, other, ++tryCount, callback) 
				}, MEM_WAIT_TIME);
			} else {
				
				// We failed, call the failure state
				callback(err, null);
			}
		} else {
			
			// We succeeded! Call the success state!
			callback(null, result);
		}
	});
}

/**
 * Write data to redis, recursing up to REDIS_ATTEMPTS times
 */
function writeToRedis(func, redisClient, tournamentId, winTotal, member, tryCount, callback) {
	
	redisClient[func](tournamentId.toString(), winTotal, member, function(err, result) {
		if (err) {
			if (tryCount < REDIS_ATTEMPTS) {

				console.warn("Attempt " + tryCount + " for Memcached write failed, retrying in " + REDIS_WAIT_TIME + "ms", err);

				setTimeout(function(){

					writeToRedis(func, redisClient, tournamentId, member, winTotal, ++tryCount, callback)
				}, REDIS_WAIT_TIME);
			} else {
				
				// We failed, call the failure state
				callback(err, null);
			}
		} else {
			
			// We succeeded! Call the success state!
			callback(null, result);
		}
	});	
}

exports.writeToSQL = writeToSQL;
exports.writeToMC = writeToMC;
exports.writeToRedis = writeToRedis;
