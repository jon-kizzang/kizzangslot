###

Redis Leaderboard Reforming Script
By The Engine Company (theengine.co)

This script is run directly from the command line / terminal and takes a tournament ID as an argument,
running this script will reform the leaderboards for the provided tournament using the available session
and log data for that tournament. This process may take some time.

###

#REQUIRE# (In alphabetical order)
async = require 'async'
common = require './include/common'
fs = require 'fs'
mysql = require 'mysql2'
redis = require 'redis'
xml2js = require 'xml2js'


#----------------------------------------------------------------------------------#

#VARIABLES#
#XML parsing
parser = new xml2js.Parser {trim:true}
xmlData = fs.readFileSync __dirname + '/slotserver.xml'


#MySQL
staticReadPool = null #Pool used to read from the static database
dynamicReadPools = [] #Pools used to write to the static databases
dynamicCount = 0 #The number of dynamic pools, used for hashing
poolConnectionLimit = 32 #Hard coded connection limit for mySQL pools

#Redis
redisClient = null


#Logging
startTime = new Date()
setupStartTime = null
repairStartTime = null
lastLog = new Date() #The time of our last log
operationStart = null #The time when the current operation started
updateTime = 1000 #How many milliseconds must pass before we log our status again
completeCount = 0
totalCount = null


#Data 
tournamentId = null
sessionData = null

#----------------------------------------------------------------------------------#

#PROCESS#
run = ->
	setupStartTime = new Date()

	console.log ""
	console.log "--------------------Begin setup--------------------"
	tournamentId = parseInt process.argv[2]

	#Make sure we actually have a tournament
	if not tournamentId

		console.error "No tournament provided!"
		process.exit()

	#Use the XML data to get the redis and mySQL information
	parser.parseString xmlData, ($err, $result) ->

		if $err 

			console.error "Could not read XML file: " + $err
			process.exit()

		config = $result.configuration

		#Setup mySQL pools
		gotStatic = false #We must always have a static database
		gotDynamic = false #We must always have at least one dynamic database

		#Helper that creates the pools
		createPool = (dataObj) ->

			dbPoolOptions =

				host: dataObj.host[0]
				port: parseInt dataObj.port[0]
				user: dataObj.user[0]
				password: dataObj.password[0]
				database: dataObj.database[0]
				debug: common.toBoolean config.debug[0]
				waitForConnections: true
				queueLimit: 0
				connectionLimit: poolConnectionLimit

			return mysql.createPool dbPoolOptions

		for i in [0..(config.mySQL.length) - 1]

			if parseInt(config.mySQL[i].ID[0]) == -1

				gotStatic = true

				#Otherwise, get the read pool data
				log "Creating staticReadPool..."
				staticReadPool = createPool config.mySQL[i].readOnly[0]
				log "staticReadPool Created!"
				console.log ""

			else if config.mySQL[i].ID[0] >= 0

				#This is a dynamic database (all IDs below -1 are ignored)
				gotDynamic = true

				#Otherwise, get the read pool data
				log "Creating dynamicReadPools " + dynamicCount + "..."
				dynamicReadPools[dynamicCount] = createPool config.mySQL[i].readOnly[0]
				log "dynamicReadPools " + dynamicCount + " Created!"
				console.log ""

				dynamicCount++

		if not gotStatic or not gotDynamic

			#If we are missing a pool, exit
			console.log "ERROR: MISSING DATABASE. Static Pool Status: " + gotStatic ". Dynamic Pool Status: " + gotDynamic
			process.exit()

		#Setup Redis
		redisIp = config.redis[0].ip[0]
		redisPort = config.redis[0].port[0]

		redisClient = redis.createClient redisPort, redisIp, {}

		redisClient.on "error", ($err) ->

			console.warn "REDIS ERROR: " + $err

		#We have all of our connections, get the number of sessions
		getSessionData()


getSessionData = ->

	#First get all of the required session data
	log "Getting session data..."

	sql = "SELECT SessionID, PlayerID FROM Session_?"

	args = [tournamentId]

	staticReadPool.query sql, args, ($err, $res) ->

		if $err or $res[0].SessionCount == 0

			console.error "Invalid Tournament ID: " + tournamentId + " | " + $err
			process.exit()

		else

			log "Session data received!"
			console.log ""

			totalCount = $res.length

			log "Total Sessions for tournament " + tournamentId + ": " + totalCount
			console.log ""

			sessionData = $res

			log "Beginning Data Format..."

			#Format the player and session ids into the proper format for leaderboard storage and add it to the existing object
			operationStart = new Date()

			for i in [0..totalCount - 1]

				sessionData[i].redisData = sessionData[i].SessionID + ":" + sessionData[i].PlayerID

				completeCount++

				#Log if too much time is passing!
				timedLog()

			log "Data formatting complete!"

			console.log "--------------------Setup Complete. Time Elapsed During Setup: " + getFormatTime(setupStartTime) + "--------------------"
			console.log ""

			#Begin the actual repair process
			initializeRepair()


initializeRepair = ->

	console.log "--------------------Begin Repair--------------------"
	completeCount = 0

	#Segment the session data into as many arrays as we have pool connections
	repairStartTime = new Date()
	operationStart = new Date()

	async.eachLimit sessionData, poolConnectionLimit, populateLeaderboard, (err) ->

		if err

			console.log "-------------------- =( Repair Error =( --------------------"
			throw err

		console.log "--------------------Repair Complete! Time Elapsed During Repair: " + getFormatTime(repairStartTime) + "--------------------"
		console.log ""
		process.exit()
	

populateLeaderboard = (data, callback) ->

	sql = "SELECT WinTotal FROM Log_? WHERE SessionID=? ORDER BY Gen DESC LIMIT 1"

	args = [tournamentId, parseInt(data.SessionID)]

	dynamicReadPools[parseInt(data.SessionID) % dynamicCount].query sql, args, (err, backData) ->

		completeCount++

		if err

			callback(err)

		else

			#Only add data to the leaderboard if we have some
			if backData.length > 0

				redisClient.ZADD tournamentId.toString(), backData[0].WinTotal, data.redisData, (err, res) ->

					if err

						callback(err)

					else

						timedLog()

						callback()

			else

				callback()




#----------------------------------------------------------------------------------#

#HELPER FUNCTIONS#
#Gets the estimated time to completion of the current operation in seconds
getETA = (timeElapsed, current, total) ->

	return (total / (current / timeElapsed)) - timeElapsed


#Gets the time elapsed in seconds between now and the provided time
getTimeElapsed = (time) ->

	return (new Date().getTime() -  time.getTime())


#Gets the time elapsed, formatted into hh:mm:ss:mmm format
getFormatTime = (time) ->

	retStr = ""

	t = new Date((new Date().getTime() -  time.getTime())).getTime()

	return convertToFormat(t)

	

convertToFormat = (milliseconds) ->

	#Use decimal math to cut up the milliseconds
	mmm = milliseconds % 1000
	s = Math.floor(milliseconds/1000)
	ss = s % 60
	m = Math.floor(s/60)
	mm = m % 60
	hh = Math.floor(m/60)

	#Format the attained values
	hh = hh.toString()
	mm = mm.toString()
	ss = ss.toString()
	mmm = mmm.toString()

	if hh.length == 1
		hh = "0" + hh

	if mm.length == 1
		mm = "0" + mm

	if ss.length == 1
		ss = "0" + ss

	if mmm.length == 1
		mmm = "00" + mmm
	else if mmm.length == 2
		mmm = "0" + mmm


	return hh + ":" + mm + ":" + ss + ":" + mmm



#Time based format for information logging
log = (l) ->

	console.log "[" + getFormatTime(startTime) + "] " + l


#Log that will be run on an interval while an operation is running
timedLog = () ->
	#Log if too much time is passing!
	if (new Date().getTime() - lastLog.getTime()) >= updateTime

		lastLog = new Date()

		log "Completed " + completeCount + " / " + totalCount + " | " + "Time Elapsed: " + getFormatTime(operationStart) + " | ETA: " + convertToFormat(Math.floor(getETA(getTimeElapsed(operationStart), completeCount, totalCount)))


#----------------------------------------------------------------------------------#

#The Beginning is at the end!
run()
