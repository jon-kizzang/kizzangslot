
#try
#	newrelic = require('newrelic')
#catch error
#	newrelic=false


###
Slot Server 2014
By Tony Suriyathep (tony.suriyathep@gmail.com)
Updated by The Engine Company (theengine.co)
###


#Nodetime must be required before anything else
#nodeTime = require 'nodetime'
#nodeTime.profile { accountKey: '6c221283028feaa0c531dcec73b5eb3609897ecb', appName: 'Kizzang Slot Server'}

fs = require 'fs'

os = require 'os'

mc = require 'mc'

net = require 'net'

http = require 'http'

redis = require 'redis'

mysql = require 'mysql2'

https = require 'https'

pjson = require './package.json'

crypto = require 'crypto'

xml2js = require 'xml2js'

toobusy = require 'toobusy-js'

querystring = require 'querystring'

common = require './include/common'

express = require "express"

bodyParser = require "body-parser"

urlencoder = require 'form-urlencoded'

SlotSession = require("./classes/data/SlotSession").SlotSession

Tournament = require("./classes/Tournament").Tournament

ProtocolCrypto = require("./classes/ProtocolCrypto").ProtocolCrypto

ProtocolServer = require("./classes/ProtocolServer").ProtocolServer

mySQLTest = require("./classes/verification/MySQLFormatVerification");

badTableCheck = require("./classes/include/badTableCheck.js");

DatabaseWrite = require("./classes/include/databaseWrite.js");

#Add more games here, someday make this dynamic
AngryChefsGame = require("./classes/games/AngryChefsGame").AngryChefsGame

BankrollBanditsGame = require("./classes/games/BankrollBanditsGame").BankrollBanditsGame

ButterflyTreasuresGame = require("./classes/games/ButterflyTreasuresGame").ButterflyTreasuresGame

RomancingRichesGame = require("./classes/games/RomancingRichesGame").RomancingRichesGame

UnderseaWorldGame = require("./classes/games/UnderseaWorldGame").UnderseaWorldGame

UnderseaWorld2Game = require("./classes/games/UnderseaWorld2Game").UnderseaWorld2Game

OakInTheKitchenGame = require("./classes/games/OakInTheKitchenGame").OakInTheKitchenGame

CrusadersQuestGame = require("./classes/games/CrusadersQuestGame").CrusadersQuestGame

MummysRevengeGame = require("./classes/games/MummysRevengeGame").MummysRevengeGame

GhostTreasuresGame = require("./classes/games/GhostTreasuresGame").GhostTreasuresGame

PenguinRichesGame = require("./classes/games/PenguinRichesGame").PenguinRichesGame

BountyGame = require("./classes/games/BountyGame").BountyGame

FatCat7Game = require("./classes/games/FatCat7Game").FatCat7Game

HolidayJoyGame = require("./classes/games/HolidayJoyGame").HolidayJoyGame

MoneyBoothGame = require("./classes/games/MoneyBoothGame").MoneyBoothGame

HappyNewYearGame = require("./classes/games/HappyNewYearGame").HappyNewYearGame

GummiBarGame = require("./classes/games/GummiBarGame").GummiBarGame

AprilMadnessGame = require("./classes/games/AprilMadnessGame").AprilMadnessGame

AstrologyAnswersGame = require("./classes/games/AstrologyAnswersGame").AstrologyAnswersGame

XtremeCashGame = require("./classes/games/XtremeCashGame").XtremeCashGame

FireHouseFrenzyGame = require("./classes/games/FireHouseFrenzyGame").FireHouseFrenzyGame

MonkeyMadnessGame = require("./classes/games/MonkeyMadnessGame").MonkeyMadnessGame

DiamondStreakGame = require("./classes/games/DiamondStreakGame").DiamondStreakGame

PaymentPanicGame = require("./classes/games/PaymentPanicGame").PaymentPanicGame

PandaPayoutGame = require("./classes/games/PandaPayoutGame").PandaPayoutGame

PuppyCashGame = require("./classes/games/PuppyCashGame").PuppyCashGame

PlanetaryPlunderGame = require("./classes/games/PlanetaryPlunderGame").PlanetaryPlunderGame

AlleyCatsGame = require("./classes/games/AlleyCatsGame").AlleyCatsGame

AsteroidsGame = require("./classes/games/AsteroidsGame").AsteroidsGame

TurkeyFeastGame = require("./classes/games/TurkeyFeastGame").TurkeyFeastGame

StockingStuffersGame = require("./classes/games/StockingStuffersGame").StockingStuffersGame

CentipedeGame = require("./classes/games/CentipedeGame").CentipedeGame

#==================================================================================================#

#VARS

#General

dbTime = null #Store the current time

parser = new xml2js.Parser {trim:true}

app = express()

BUFSIZE_FS = 13

BUFSIZE_LOG = 33

NO_API = "no_api"

IN_TOP_THREE = "in_top_three"

API_TIMEOUT = "api_timeout"

SQL_ATTEMPTS = 6 #How many attempts should be made to register data to SQL
SQL_WAIT_TIME = 5000 #How much time (in ms) to wait before re-trying a SQL log

MEM_ATTEMPTS = 6 #How many attempts should be made to register data to memcached
MEM_WAIT_TIME = 5000 #How much time (in ms) to wait before re-trying a memcached log

REDIS_ATTEMPTS = 6 #How many attempts should be made to register data to redis
REDIS_WAIT_TIME = 5000 #How much time (in ms) to wait before re-trying a redis log

#Server information

serverId = 0

serverPort = 0

serverAllowCheat = false

serverDebug = false

serverLogDebug = false

#Initialize the password as some random mess just in case the xml data fails
serverAccessPass = 'dwagsvjnwkdmelfwerfdsac	dwd42'

serverRequireHostCheck = true

serverRequireAPICall = true

serverBackdoorHost = "stageapi.kizzang.com"

#The number of miliseconds it takes for a request to the kizzang API server to timeout
serverAPITimeout = 5000

#VALUE HARDCODED TO 25 IF A `betTotal` VALUE IS NOT INCLUDED IN THE CONFIG XML
serverBetTotal = 25 #Used by the app to determine if a special win state should be used

#What time relative to GMT to return when returning time strings
displayTime = {
	offset: "-08:00",
	timezone: "PST"
};

dbTimeOffset = "+00:00"; #The time relative to GMT the database is running at


#Math

mathList = [] #Straight list of math IDs that where loaded

mathGames = [] #Classes that will process spins



#XML files

xmlMathFiles = [] #Entire contents of math XML by ['undersea']

xmlThemeFiles = []



#mySQL database Pools

staticWritePool = null #Pool used for writing to the static database

staticReadPool = null #Pool used to read from the static database

dynamicWritePools = [] #Pools used to write to the dynamic databases

dynamicReadPools = [] #Pools used to write to the static databases

dynamicCount = 0 #The number of dynamic pools, used for hashing

poolConnectionLimit = 32 #Hard coded connection limit for mySQL pools


#Memcached client

mcClient = null

#faux-enum for flags used by memcached
memcachedFlags =

	LOG_DATA: "0"

	SESSION_DATA: "1"

	SCREEN_NAME: "2"

	FACEBOOK_ID: "3"

screenNameExp = 259200 #An amount of seconds equal to 3 days


#Redis Client
redisCount = null #The number of redis Servers we have access to

redisClient = null



#Additional Data Tracking

tournamentData = {} #Cached tournament data

gameData = {} #Cached game data

lastPlayerId = null #The ID of the last player to register


#This gets the play limit per person, post with body user_id: PlayerID

DGL_POST =

	host: 'teamdevlb.kizzang.com'



	port: 443

	path: '/mobile/todaysTotalGameCount'

	method: 'POST'

	rejectUnauthorized: false

	headers:

		'Content-Type': 'application/x-www-form-urlencoded'

		'Authorization': 'Basic ' + new Buffer('tdptb2013:ItzZXIaPI7Q2r').toString('base64')

#The current version
versionNumber = "";





#==================================================================================================#

#http://stackoverflow.com/questions/13854105/convert-javascript-date-object-to-pst-time-zone



#Check for standard timezone offset

getStandardTimezoneOffset = (dt)->

	jan = new Date(dt.getFullYear(), 0, 1)

	jul = new Date(dt.getFullYear(), 6, 1)

	return Math.max(jan.getTimezoneOffset(), jul.getTimezoneOffset())



#Check for daylight savings

isDaylightSavingsOn = (dt)->

	return dt.getTimezoneOffset() < getStandardTimezoneOffset(dt)



#Get current date with PST (Pacific Standard Time) and DST (Daylight Savings Time)

getCurrentDate = (addHours=-7) ->

	d = new Date()

	#if isDaylightSavingsOn(d) then addHours++

	return new Date(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), d.getUTCHours()+addHours, d.getUTCMinutes(), d.getUTCSeconds())


#Parse the tournament ID out of a token string
getTournamentFromToken = (tokenString) ->
	return parseInt tokenString.slice(0, tokenString.indexOf(":"))





#==================================================================================================#

#Get configuration XML





readMathFiles = ($onComplete)->

	dir = './xml/math/'

	fs.readdir dir, ($err,$files)->

		if $err then throw $err



		#Count only XML files

		c = 0

		total = 0

		$files.forEach ($file)->

			if not common.endsWith($file,'.xml') then return

			total++



		#Read each one

		$files.forEach ($file)->
			console.log "Reading math file"
			if not common.endsWith($file,'.xml') then return

			fs.readFile dir+$file, 'utf-8', ($err,$data)->

				if $err then throw $err
				console.log "Read file"


				#Parse

				parser.parseString $data, ($err, $result) ->

					if $err then throw $err
					console.log "parsed File"

					id = $result.math.$.id

					xmlMathFiles[id] = $result.math

					mathList.push id #Update the list

					console.log "Loading game: " + id

					#Load game
					if id=="butterflytreasures"

						game = new ButterflyTreasuresGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."

					else if id=="bankrollbandits"

						game = new BankrollBanditsGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."

					else if id=="angrychefs"

						game = new AngryChefsGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."

					else if id=="romancingriches"

						game = new RomancingRichesGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."

					else if id=="underseaworld"

						game = new UnderseaWorldGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."

					else if id=="underseaworld2"

						game = new UnderseaWorld2Game()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."

					else if id=="oakinthekitchen"

						game = new OakInTheKitchenGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."
					
					else if id=="crusadersquest"

						game = new CrusadersQuestGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."
						
					else if id=="mummysrevenge"

						game = new MummysRevengeGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."	
					
					else if id=="penguinriches"

						game = new PenguinRichesGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."	

					else if id=="ghosttreasures"

						game = new GhostTreasuresGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."
					
					else if id=="bounty"

						game = new BountyGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."
					
					else if id=="fatcat7"

						game = new FatCat7Game()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."
				
					else if id=="holidayjoy"

						game = new HolidayJoyGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."
						
					else if id=="moneybooth"
					
						game = new MoneyBoothGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."
					
					else if id=="happynewyear"

						game = new HappyNewYearGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."
					
					else if id=="gummibar"

						game = new GummiBarGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."

					else if id=="aprilmadness"

						game = new AprilMadnessGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."
						
					else if id=="astrologyanswers"

						game = new AstrologyAnswersGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."

					else if id=="xtremecash"

						game = new XtremeCashGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."

					else if id=="firehousefrenzy"

						game = new FireHouseFrenzyGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."

					else if id=="monkeymadness"

						game = new MonkeyMadnessGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."

					else if id=="diamondstreak"

						game = new DiamondStreakGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."

					else if id=="paymentpanic"

						game = new PaymentPanicGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."

					else if id=="pandapayout"

						game = new PandaPayoutGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."

					else if id=="puppycash"

						game = new PuppyCashGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."

					else if id=="planetaryplunder"

						game = new PlanetaryPlunderGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."

					else if id=="alleycats"

						game = new AlleyCatsGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."

					else if id=="asteroids"

						game = new AsteroidsGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."

					else if id=="turkeyfeast"

						game = new TurkeyFeastGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."

					else if id=="stockingstuffers"

						game = new StockingStuffersGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."

					else if id=="centipede"

						game = new CentipedeGame()

						game.importGame $result.math

						game.allowCheat = serverAllowCheat

						mathGames[id] = game

						console.log "	 Read math XML id="+id+" ["+dir+$file+"]."

					console.log "loaded games"
					#Check for end

					c++

					if c == total then readThemeFiles $onComplete





readThemeFiles = ($onComplete)->

	dir = './xml/theme/'

	fs.readdir dir, ($err,$files)->

		if $err then throw $err



		#Count only XML files

		c = 0

		total = 0

		$files.forEach ($file)->

			if not common.endsWith($file,'.xml') then return

			total++



		#Read each one

		$files.forEach ($file)->

			if not common.endsWith($file,'.xml') then return

			fs.readFile dir+$file, 'utf-8', ($err,$data)->

				if $err then throw $err



				#Parse

				parser.parseString $data, ($err, $result) ->

					if $err then throw $err

					id = $result.theme.$.id

					xmlThemeFiles[id] = $result.theme

					console.log "	 Read theme XML id="+id+" ["+dir+$file+"]."



					#Check for end

					c++

					if c == total then getServerId $onComplete





getServerId = ($onComplete) ->

	staticWritePool.getConnection ($err,$conn) ->

		if $err

			console.log 'Database: ' + $err

			process.exit()

			return

		sql = "INSERT INTO SlotServer (Host,Port,CryptoOn,CryptoKey,Debug,MathList,StartDate) VALUES ("

		sql += $conn.escape(os.hostname())+","

		sql += serverPort+","

		sql += (if ProtocolCrypto.on then 1 else 0)+","

		sql += $conn.escape(ProtocolCrypto.key)+","

		sql += (if serverDebug then 1 else 0)+","

		sql += $conn.escape(mathList.join(','))+","

		sql += $conn.escape(getCurrentDate())

		sql += ")"



		$conn.query sql, ($err,$result) ->

			$conn.release()

			if $err

				msg = badTableCheck($err) + "Could not get new server ID file: " + $err

				console.error msg

				process.exit()

				return

			serverId = $result.insertId

			console.log "	 Server #"+serverId+" inserted into table SlotServer."

			if $onComplete then $onComplete()


getConfiguration = ($onComplete) ->

	console.log '\nReading configuration XML ...'



	xmlData = fs.readFileSync __dirname + '/slotserver.xml'



	parser.parseString xmlData, ($err, $result) ->

		if $err

			console.log "	 Could not read XML file."

			process.exit()

			return


		#General setup
		config = $result.configuration

		serverPort = parseInt process.env.PORT

		serverDebug = common.toBoolean process.env.DEBUG

		serverLogDebug = common.toBoolean process.env.LOG_DEBUG

		serverAllowCheat = common.toBoolean process.env.ALLOW_CHEAT

		serverAccessPass = process.env.ACCESS_PASS

		serverRequireHostCheck = common.toBoolean process.env.REQ_HOST_NAME_CHECK

		serverRequireAPICall = common.toBoolean process.env.REQ_API_CALL

		serverBetTotal = parseInt process.env.TOTAL_BET

		serverBackdoorHost = process.env.BACKDOOR_HOST_NAME

		serverAPITimeout = parseInt process.env.API_TIMEOUT

		poolConnectionLimit = parseInt process.env.POOL_CONNECTION_LIMIT
		
		if (config.displayTime && config.displayTime.length > 0)
			displayTime.offset = process.env.TIME_OFFSET
			displayTime.timezone = process.env.TIMEZONE
		else
			console.warn("WARNING: No displayTime set, setting to default")
		
		dbTimeOffset = process.env.DB_TIMEZONE

		#Setup mySQL pools
		gotStatic = false #We must always have a static database
		gotDynamic = false #We must always have at least one dynamic database

		#Helper that creates the pools
		createPool = (dataObj) ->

			dbPoolOptions =

				host: process.env.DB_HOST

				port: parseInt process.env.DB_PORT

				user: process.env.DB_USER

				password: process.env.DB_PASSWORD

				database: process.env.DB_DATABASE

				debug: serverDebug

				waitForConnections: true

				queueLimit: 0

				connectionLimit: poolConnectionLimit

			return mysql.createPool dbPoolOptions

		for i in [0..(config.mySQL.length) - 1]

			if parseInt(config.mySQL[i].ID[0]) == -1

				gotStatic = true

				#Set the data for the static write pool
				console.log "Writing to staticWritePool"
				staticWritePool = createPool config.mySQL[i].readWrite[0]

				#Otherwise, get the read pool data
				console.log "Writing to staticReadPool"
				staticReadPool = createPool config.mySQL[i].readOnly[0]

			else if config.mySQL[i].ID[0] >= 0

				#This is a dynamic database (all IDs below -1 are ignored)
				gotDynamic = true

				#Set the data for the dynamic write pool
				console.warn "Writing to dynamicWritePools " + dynamicCount
				dynamicWritePools[dynamicCount] = createPool config.mySQL[i].readWrite[0]

				#Otherwise, get the read pool data
				console.warn "Writing to dynamicReadPools " + dynamicCount
				dynamicReadPools[dynamicCount] = createPool config.mySQL[i].readOnly[0]

				dynamicCount++

		if not gotStatic or not gotDynamic

			#If we are missing a pool, exit
			console.log "ERROR: MISSING DATABASE. Static Pool Status: " + gotStatic ". Dynamic Pool Status: " + gotDynamic
			process.exit()


		#Setup memcached
		customAdapter = (results) ->
			#Generate an object from the search results
			buf = results.buffer

			if results.size <= 0

				console.log("Memcached Error - No Data")

				return null

			if results.flags == memcachedFlags.LOG_DATA
				#Extract the FSTriggers buffer
				fsBuf = new Buffer(BUFSIZE_FS)
				buf.copy(fsBuf, 0, 20)

				retObj =
					Gen: buf.readUInt32BE(0)
					SpinsLeft: buf.readUInt16BE(4)
					SpinsTotal: buf.readUInt16BE(6)
					SecsLeft: buf.readUInt16BE(8)
					SecsTotal: buf.readUInt16BE(10)
					WinTotal: buf.readDoubleBE(12)
					FSTriggers: fsBuf.toString("hex")

				return retObj

			else if results.flags == memcachedFlags.SESSION_DATA

				retObj =
					SessionID: buf.readDoubleBE(0)
					PlayerID: buf.readDoubleBE(8)
					GameID: buf.readUInt32BE(16)
					StartTime: buf.readDoubleBE(20)

				return retObj

			else if results.flags == memcachedFlags.SCREEN_NAME

				return buf.toString()

			else if results.flags == memcachedFlags.FACEBOOK_ID

				return buf.toString()

			else

				console.log("Memcached Error - Invalid data flag of: " + results.flags)

				return null


		mcClient = new mc.Client(process.env.MEMCACHE_HOST, customAdapter)

		#Setup Redis
		redisIp = process.env.REDIS_HOST
		redisPort = process.env.REDIS_PORT

		redisClient = redis.createClient redisPort, redisIp, {}

		redisClient.on "error", ($err) ->

			console.log "REDIS ERROR: " + $err


		#Setup crypto

		ProtocolCrypto.on = common.toBoolean process.env.CRYPT_ON

		ProtocolCrypto.method = process.env.CRYPTO_METHOD

		ProtocolCrypto.key = process.env.CRYPTO_KEY

		console.log "	 Crypto on = "+ProtocolCrypto.on



		#Done!

		console.log "	 Configuration succeeded."



		#Get a server ID from mySQL

		readMathFiles $onComplete




#==================================================================================================#

#Compare mySQL time




#This function literally has no effect on server logic, and is completely useless
getMySqlTime = ($onComplete) ->

	console.log '\nChecking time mySQL Server versus Slot Server ...'


	#Get the time

	sql = "SELECT NOW() as dt"

	staticReadPool.query sql, ($err,$rows,$fields) ->

		if ($err)

			#We got an error!
			msg = badTableCheck($err) + "ERROR: Error getting mySQL time.\nError: " + JSON.stringify $err

			throw msg

		curTime = getCurrentDate()

		dbTime = new Date($rows[0].dt)

		console.log "	 mySQL Time = "+dbTime

		console.log "	 Server Time = "+curTime

		console.log "	 Time Difference = "+common.hoursBetween(curTime,dbTime)+" hours"

		if $onComplete then $onComplete()




#==================================================================================================#

#Socket server





#Get ranking for one SlotPlayerID

onRank = (params, response)->

	#Send response and close everything
	hasEnded = false

	endComm = ($ok,$msg,$response)->

		if not hasEnded then response.send (new ProtocolServer($ok,$msg,{command: 'rank', params: params},$response)).out()

		hasEnded = true



	if not params or not params.slotPlayerId

		endComm 0, "rank-fail-null-params"

		return



	tournamentId = null

	sessionId = null

	slotPlayerId = params.slotPlayerId

	winTotal = null

	curDate = getCurrentDate()

	log = null

	ret = []


	getTournament = ->
		#Get the player's current tournament
		sql = "SELECT TournamentID, SessionID FROM Players WHERE PlayerID=?"

		args = [slotPlayerId]

		staticReadPool.query sql, args, ($err, $backData) ->

			if $err or $backData.length == 0

				msg = badTableCheck($err) + "rank-fail-no-active-tournament"

				console.error sql 
				console.error slotPlayerId	
				console.error "rank-fail-no-active-tournament"					
				console.error $err

				endComm 0, msg

			else

				tournamentId = $backData[0].TournamentID

				sessionId = $backData[0].SessionID

				#Try to verify from our cached tournament data
				if tournamentData[$backData[0].TournamentID.toString()]

					#We found data! Keep moving
					getRank()

				else

					#We did not find data... Try querying mySQL
					sql = "SELECT * FROM SlotTournament WHERE ID=?"

					args = [$backData[0].TournamentID]

					staticReadPool.query sql, args, ($err,$backData) ->

						if $err or $tournaments.length==0

							msg = badTableCheck($err) + "rank-fail-active-tournament-not-found"

							console.log msg + ": " + $err

							endComm 0, msg

						else

							#Add this tournament to the cache
							populateTournaments $backData[0]

							getRank()



	getRank = ->
		#Get the currently selected player's total score for the current session
		member = sessionId + ":" + slotPlayerId

		redisClient.ZSCORE tournamentId.toString(), member, ($err, $res) ->

			if $err or $res == null

				console.log "rank-fail-no-player-score: " + $err

				endComm 0, "rank-fail-no-player-score"
				return

			winTotal = $res

			#Use that score to find the number of players above the selected player
			redisClient.ZCOUNT tournamentId.toString(), "(" + winTotal, "+inf", ($err, $res) ->

				if $err or $res == null

					console.log "rank-fail-get-rank-error: " + $err

					endComm 0, "rank-fail-get-rank-error"

				else

					ret =

						rank: $res + 1

						lastRank: 0

						winTotal: winTotal

					#getLastRank()
					sendRank() #TEMPORARILY SKIP getLastRank()


	sendRank = ->

		endComm 1, 'rank-ok', ret


	getTournament()







#Get the top 15 player in the tournament with the given TournamentID

onRanks = (params, response)->

	#Send response and close everything
	hasEnded = false

	endComm = ($ok,$msg,$response)->

		if not hasEnded then response.send (new ProtocolServer($ok,$msg,{command: 'ranks', params: params},$response)).out()

		hasEnded = true


	if not params or not params.tournamentId

		endComm 0,"rank-fail-null-params"

		return



	ranks = null

	curDate = getCurrentDate()

	tournamentId = params.tournamentId


	getRanks = ->

		#Get the top 15 players in descending order
		redisClient.ZREVRANGEBYSCORE tournamentId.toString(), "+inf", "-inf", "WITHSCORES", "LIMIT", 0, 15, ($err, $res) ->

			if $err or $res.length == 0

				console.log "ranks-fail-top-players: " + $err

				endComm 0, "ranks-fail-top-players"
				return

			else

				topLeft = $res.length / 2

				#Loop through the top players, creating an object
				ranks = []
				pushObject = null
				for i in [0..($res.length) - 1]

					if (i % 2) == 0

						#Create a new push object every even value
						pushObject = new Object

						#Even values are player IDs
						pushObject.PlayerID = extractRedisMember($res[i])[1]

						screenNameKey = "p" + pushObject.PlayerID.toString()

						getMemcachedData(screenNameKey, (($err, $res, $index)->

							if $err or !$res

								msg = badTableCheck($err) + "ranks-fail-player-not-found"

								console.warn msg + ": " + $err

								endComm 0, msg

							else
							
								pushIndex = $index / 2

								if ranks[pushIndex]

									ranks[$index / 2].ScreenName = $res.ScreenName

									if ($res.FacebookID and $res.FacebookID != "")
										ranks[$index / 2].FacebookID = $res.FacebookID

									if --topLeft == 0

										if params.playerId then getRank()

										else endComm 1, 'ranks-ok', {tournamentId:tournamentId, ranks:ranks}

								else

									ranks[pushIndex] = {ScreenName: $res}), i)

					else

						#Odd values are scores
						pushObject.WinTotal = $res[i]

						#Add the push object every odd value
						pushIndex = Math.floor(i / 2)

						if ranks[pushIndex]

							ranks[pushIndex].PlayerID = pushObject.PlayerID

							ranks[pushIndex].WinTotal = pushObject.WinTotal

							if --topLeft == 0

								if params.playerId then getRank()

								else endComm 1, 'ranks-ok', {tournamentId:tournamentId, ranks:ranks}

						else

							ranks[Math.floor(i / 2)] = pushObject


	getRank = ->
		#Get the currently selected player's session ID
		sql = "SELECT SessionID FROM Players WHERE PlayerID=?"

		args = [params.playerId]

		staticReadPool.query sql, args, ($err, $backData) ->

			if $err or $backData.length == 0

				msg = badTableCheck($err) + "ranks-none"

				console.log msg + ": " + $err

				endComm 1, msg, {tournamentId:tournamentId, ranks:ranks}
				return

			#Get the currently selected player's total score for their current session
			member = $backData[0].SessionID + ":" + params.playerId

			redisClient.ZSCORE tournamentId.toString(), member, ($err, $res) ->

				if $err or $res == null

					endComm 1, "ranks-ok-self-not-found", {tournamentId:tournamentId, ranks:ranks}
					return

				winTotal = $res

				#Use that score to find the number of players above the selected player
				redisClient.ZCOUNT tournamentId.toString(), "(" + winTotal, "+inf", ($err, $res) ->

					if $err

						console.log "ranks-fail-get-rank-error: " + $err

						endComm 0, "ranks-fail-get-rank-error"

					else

						endComm 1, 'ranks-ok', {tournamentId:tournamentId,you:{ rank:$res + 1, winTotal: winTotal } ,ranks:ranks}


	getRanks()




#List games with the times that they are active

onTimes = (response)->

	arr = []

	curDate = getCurrentDate()

	hh = ("00"+curDate.getHours()).slice(-2)

	mm = ("00"+curDate.getMinutes()).slice(-2)

	ss = ("00"+curDate.getSeconds()).slice(-2)

	curTime = hh+":"+mm+":"+ss



	#Check if trying to go to a valid tournament

	getTimes = ->

		sql = "SELECT * FROM SlotGame WHERE ?<EndTime ORDER BY EndTime"

		args = [curTime]

		staticReadPool.query sql, args, ($err,$times) ->

			if $err or $times.length==0

				msg = badTableCheck($err) + "times-fail"

				console.log msg + ": " + $err

				endComm 0, msg

			else

				for time in $times

					obj =

						id: time.ID

						name: time.Name

						startTime: ""+time.StartTime

						endTime: ""+time.EndTime

						spinsTotal: time.SpinsTotal

						secsTotal: time.SecsTotal

					arr.push obj

				endComm 1, 'times-ok', {times:arr}



	#Send response and close everything
	hasEnded = false

	endComm = ($ok,$msg,$response)->

		if not hasEnded then response.send (new ProtocolServer($ok,$msg,{command: 'times'},$response)).out()

		hasEnded = true


	getTimes()





#List games

onGames = (response)->

	arr = []

	curDate = getCurrentDate()



	#Check if trying to go to a valid tournament

	getGames = ->

		sql = "SELECT * FROM SlotGame ORDER BY ID"

		args = [common.toMySqlDate(curDate),curDate]

		staticReadPool.query sql, args, ($err,$games) ->

			if $err or $games.length==0

				msg = badTableCheck($err) + "games-fail"

				console.log msg + ": " + $err

				endComm 0, msg

			else

				for game in $games

					obj =

						id: game.ID

						name: game.Name

						theme: game.Theme

						math: game.Math

					arr.push obj

				endComm 1, 'games-ok', {games:arr}



	#Send response and close everything
	hasEnded = false

	endComm = ($ok,$msg,$response)->

		if not hasEnded then response.send (new ProtocolServer($ok,$msg,{command: 'games'},$response)).out()


	getGames()



#Get information on all of the tournaments currently running and which tournament the player is currently in, if applicable

onList = (params, response)->

	#Send response and close everything
	hasEnded = false

	endComm = ($ok,$msg,$response)->

		if not hasEnded then response.send (new ProtocolServer($ok,$msg,{command: 'list', params: params},$response)).out()

		hasEnded = true


	arr = []

	tournaments = null

	curDate = getCurrentDate()

	retObject = { tournamentInfo: null, playerTournamentId: null }


	#Check if trying to go to a valid tournament

	getTournaments = ->

		sql = "SELECT * FROM SlotTournament WHERE EndDate>? AND StartDate<? ORDER BY type"

		args = [ curDate, curDate ]

		staticReadPool.query sql, args, ($err, $backData) ->

			if $err or not $backData[0]

				msg = badTableCheck($err) + 'list-fail-no-tournaments'

				console.log msg + ": " + $err

				endComm 0, msg

			else

				retObject.tournamentInfo = $backData

				#Convert the date into nice PST
				for i in [0..retObject.tournamentInfo.length - 1]
					retObject.tournamentInfo[i].StartDate = new Date(retObject.tournamentInfo[i].StartDate).toString()
					retObject.tournamentInfo[i].EndDate = new Date(retObject.tournamentInfo[i].EndDate).toString()

					#Parse the prize list for nicer responses
					retObject.tournamentInfo[i].PrizeList = JSON.parse retObject.tournamentInfo[i].PrizeList

					#Use this opportunity to populate the tournamentData object
					if not tournamentData[$backData[i].ID.toString()]
						populateTournaments $backData[i]


				if params.playerId

					getPlayerInfo()

				else

					finishCommand()

	getPlayerInfo = ->

		sql = "SELECT TournamentID FROM Players WHERE PlayerID=?"

		args = [ params.playerId ]

		staticReadPool.query sql, args, ($err, $backData) ->

			if $err or not $backData[0]

				msg = badTableCheck($err) + "list-fail-no-tournamentId"

				console.log msg + ": " + $err

				endComm 0, msg

			else

				retObject.playerTournamentId = $backData[0].TournamentID

				finishCommand()



	finishCommand = ->

		endComm 1, "list-ok", retObject



	getTournaments()

#Get information on all of the tournaments and games currently running. This information is required by the game lobby

onLobbyList = (response)->

	hasEnded = false

	endComm = ($ok,$msg,$response)->

		if not hasEnded then response.send (new ProtocolServer($ok,$msg,{command: 'lobby-list'},$response)).out()

		hasEnded = true


	tournamentArr = [] #Array that will hold tournament objects

	gameArr = [] #Array that will hold game objects

	curDate = getCurrentDate()

	retObj = { tournaments: null, games: null, version: versionNumber } #Returned object



	getData = ->

		#Do asynchronous operations!
		completeCount = 0

		sql = "SELECT *, StartDate AS ConvertedStartDate, EndDate AS ConvertedEndDate FROM SlotTournament WHERE ?>=StartDate AND ?<=EndDate order by type"
		
		console.log(dbTimeOffset, displayTime)
		args = [curDate, curDate]

		staticReadPool.query sql, args, ($err,$tournaments) ->

			if $err or $tournaments.length==0

				msg = badTableCheck($err) + "lobby-list-fail-no-tournaments"

				console.log msg + ": " + $err

				endComm 0, msg

			else

				for tournament in $tournaments
										
					# Slice the converted strings off at the timezone and add the timezone we want
					convertedStartString = tournament.ConvertedStartDate.toString();
					convertedStartString = convertedStartString.slice(0, convertedStartString.indexOf("GMT"))
					
					convertedEndString = tournament.ConvertedEndDate.toString();
					convertedEndString = convertedEndString.slice(0, convertedEndString.indexOf("GMT"))
					
					obj =
						name: tournament.type
	
						id: tournament.ID
						
						startTime: convertedStartString

						endTime: convertedEndString

						prizeList: JSON.parse tournament.PrizeList
            
						type: tournament.type
            
						title: tournament.Title

						games: tournament.GameIDs
						

					tournamentArr.push obj

				retObj.tournaments = tournamentArr

				if ++completeCount == 2

					endComm 1, 'lobby-list-ok', retObj


		staticReadPool.query "SELECT ID, Name, Theme, Math, SpinsTotal, SecsTotal, Disclaimer, adPlacement FROM SlotGame", ($err, $games) ->

			if $err or $games.length==0

				msg = badTableCheck($err) + "lobby-list-fail-no-games"

				endComm msg + ": " + $err

				endComm 0, msg

			else

				for game in $games

					obj =

						gameId: game.ID

						name: game.Name

						theme: game.Theme

						spinsTotal: game.SpinsTotal

						secsLeft: game.SecsTotal

						secsTotal: game.SecsTotal

						disclaimer: game.Disclaimer

						adPlacement: game.adPlacement

					gameArr.push obj

				retObj.games = gameArr

				if ++completeCount == 2

					endComm 1, "lobby-list-ok", retObj


	getData()


	

#Get the math and theme assets for a specific game

onAssets = (params, response)->

	#Send response and close everything
	hasEnded = false

	endComm = ($ok,$msg,$response)->

		if not hasEnded then response.send (new ProtocolServer($ok,$msg,{command: 'assets', params: params},$response)).out()

		hasEnded = true


	if not params or not params.gameId

		endComm 0, 'assets-fail-null-params'
		return#Return to prevent further calculation


	curDate = getCurrentDate()

	themeId = null

	mathId = null

	gameId = params.gameId



	getAssetsName = ->

		#Try and get the game data from our cache
		if gameData[gameId.toString()]

			#Found data!
			themeId = gameData[gameId.toString()].Theme
			mathId = gameData[gameId.toString()].Math

			sendAssets()

		else

			#We did not find data, try mySQL
			sql = "SELECT * FROM SlotGame WHERE ID=?"

			args = [gameId]

			staticReadPool.query sql, args, ($err, $backData) ->

				if $err or $backData.length == 0

					msg = badTableCheck($err) + "assets-fail-game-not-found"

					console.log msg + ": " + $err

					endComm 0, msg

				else

					themeId = $backData[0].Theme
					mathId = $backData[0].Math

					#Enter the found data into the gameData object
					populateGames $backData[0]

					sendAssets()


	sendAssets = ->

		obj =

			math: xmlMathFiles[mathId]

			theme: xmlThemeFiles[themeId]

		#Make sure there is math and theme data before returning it
		if not obj.math
			endComm 0, 'assets-fail-no-math-data', { mathId: mathId }
			return

		if not obj.theme
			endComm 0, 'assets-fail-no-theme-data', { themeId: themeId }
			return

		endComm 1, 'assets-ok', obj



	return getAssetsName()


#Join tournament NO LONGER USED

onJoin = (params, response)->

	response.send (new ProtocolServer(1, "join-ok-command-not-used", {command: 'join', params: params})).out()




#Spin

onSpin = (params, response)->

	#Send response and close everything
	hasEnded = false

	endComm = ($ok,$msg,$response)->

		if not hasEnded then response.send (new ProtocolServer($ok,$msg,{command: 'spin', params:params},$response)).out()

		hasEnded = true



	if not params or not params.playerToken

		endComm 0,'spin-fail-null-params'

		return

	if not params.appToken

		endComm 0, "spin-fail-no-appToken"

		return

	if not params.apiKey

		endComm 0, "spins-fail-no-apiKey"

		return


	curDate = getCurrentDate()

	tournamentId = getTournamentFromToken(params.playerToken)

	secsLeft = 0

	game = null

	secsTotal = null #The amount of seconds allowed for the game

	spinsTotal = null #The amount of spins allowed for the game

	startTime = null #The time at which our player started their session

	math = null

	sessionId = null

	playerId = null

	spinData = null

	winTotal = null

	gen = null

	gameId = null

	messageAppend = "" #Used in case the API call fails on the last spin


	#Checks if the requested tournament is currently running
	checkTournament = ->

		if tournamentData[tournamentId.toString()]

			#We found a valid tournament with the requested ID, now determine if it is active
			if tournamentData[tournamentId.toString()].StartDate < curDate and tournamentData[tournamentId.toString()].EndDate > curDate

				getPlayer()

			else

				#Tournament is not good
				endComm 0, "spin-fail-tournament-ended"

		else

			#No tournament found, check mySQL
			sql = "SELECT * FROM SlotTournament WHERE ID=?"

			args = [tournamentId]

			staticReadPool.query sql, args, ($err, $backData) ->

				if $err or $backData.length == 0

					msg = badTableCheck($err) + "spin-fail-tournament-not-found"

					console.error msg + ": " + $err

					endComm 0, msg
				else

					#Found data in mySQL, populate
					populateTournaments $backData[0]

					#Check if the tournament is active
					if $backData[0].StartDate < curDate and $backData[0].EndDate > curDate

						getPlayer()

					else

						#The tournament is not active
						endComm 0, "spin-fail-tournament-ended"


	#Gets the player's current session info
	getPlayer = ->

		keyStr = "s" + params.playerToken

		getMemcachedData keyStr, ($err, $res) ->

			if $err or not $res

				msg = badTableCheck($err) + "spin-fail-invalid-player"

				console.log msg + ": " + $err

				endComm 0, msg

			else

				startTime = parseInt $res.StartTime

				sessionId = $res.SessionID

				playerId = $res.PlayerID

				gameId = $res.GameID

				#Get previous log data to determine the player's eligibility to play
				getGameData()


	#Get the game data
	getGameData = ->

		#First try the local cache
		if gameData[gameId.toString()]

			#Game data found!
			secsTotal = gameData[gameId.toString()].SecsTotal

			spinsTotal = gameData[gameId.toString()].SpinsTotal

			math = gameData[gameId.toString()].Math

			getPlayerLog()

		else

			#No data, try mySQL
			sql = "SELECT * FROM SlotGame WHERE ID=?"

			args = [gameId]

			staticReadPool.query sql, args, ($err, $backData) ->

				if $err or not $backData[0]

					msg = badTableCheck($err) + "spin-fail-game-not-found"

					console.log msg + ": " + $err

					endComm 0, msg

				else

					#Data found! Populate the local cache with it
					populateGames $backData[0]

					secsTotal = $backData[0].SecsTotal

					spinsTotal = $backData[0].SpinsTotal

					math = $backData[0].Math

					#Now get the player information from the relevant Session table
					getPlayerLog()


	getPlayerLog = ->

		#Get our game in preparation
		game = mathGames[math]

		keyStr = "l" + tournamentId + ":" + sessionId

		getMemcachedData keyStr, ($err, $res) ->

			if $err

				msg = badTableCheck($err) + "spin-fail-log-error"

				console.log msg + ": " + $err

				endComm 0, msg

			else

				#Found data!
				verifyPlayerLog $res


	verifyPlayerLog = (logData) ->

		state = null

		if not logData
			
			#Make sure that we still have some time left in the game (There have been no spins for this session, so we don't have to worry about bonus time)
			secsSinceReg = common.secondsBetween (new Date(parseInt startTime)), curDate

			if secsSinceReg <= 0

				endComm 0, "spin-fail-out-of-time"
				return

			secsLeft = secsTotal

			secsTotal += secsSinceReg

			state = game.createState spinsTotal, secsTotal

			gen = 1


		else if logData.SpinsLeft <= 0 and logData.fsOn == false
			#ADDED FS STATE CHECK
			#We have no spins
			endComm 0, "spin-fail-no-spins"

			return


		else if logData.SpinsLeft > 0 or logData.fsOn == true

			#Make sure we have time left in the game (Taking bonus time into account)
			secsTotal = logData.SecsTotal

			secsLeft = secsTotal - (common.secondsBetween (new Date(startTime)), curDate)

			if secsLeft <= 0

				endComm 0, "spin-fail-out-of-time_2"
				return

			state = game.createState logData.SpinsTotal, secsTotal
			
			gen = logData.Gen + 1

			#Alter the state to include important data
			state.spinsLeft = logData.SpinsLeft
			state.winTotal = logData.WinTotal
			state.secsLeft = logData.SecsLeft

			#Parse the FSTrigger Data and alter the state with it
			extractFSTriggers logData.FSTriggers, state

		processSpin(JSON.stringify({state:state}))

	processSpin = (data) ->

		#Do one spin!
		state = JSON.parse(data).state

		spinData = game.spin state

		#Account for possible increases in time
		secsLeft = spinData.state.secsTotal - (common.secondsBetween (new Date(startTime)), curDate)

		#Error if their are greater than 6 reels, we can't store that!
		if spinData.offsets.length > 6
			endComm 0, "spin-fail-invalid-reel-number"
			return

		#Send a post to the Kizzang API if we are in our final spin, and we are not in the top 3
		if spinData.state.spinsLeft <= 0
			determineTopness(spinData.state.winTotal)
		else
			logSpinData(NO_API)
		

	determineTopness = (totalScore) ->

		#Get the top 3 players
		redisClient.ZREVRANGEBYSCORE tournamentId.toString(), "+inf", "-inf", "WITHSCORES", "LIMIT", 0, 3, ($err, $res) ->

			if $err

				console.error "spin-leaderboard-error: " + $err

			else	
			
				#If there are fewer then 6 values, we have less then three players at the top, so we are automatically in the top 3
				if $res.length < 6

					#logSpinData(IN_TOP_THREE)

					#Generate the body data
					gameInfo =

						type: "slotTournament"
						serialNumber: generateSerialNumber()
						entry: sessionId

					bodyData = JSON.stringify gameInfo

					apiHTTPRequest "/api/eventnotification/chedda/add", params.appToken, params.apiKey, logSpinData(IN_TOP_THREE), bodyData, true

					return #Stop!

				#The last value is the lowest score of the top 3
				if $res[5] > totalScore

					#Generate the body data
					gameInfo =

						type: "slotTournament"
						serialNumber: generateSerialNumber()
						entry: sessionId

					bodyData = JSON.stringify gameInfo

					#We are NOT in the top 3! Send the message to the API
					apiHTTPRequest "/api/eventnotification/chedda/add", params.appToken, params.apiKey, logSpinData, bodyData, true

				else

					#We are in the top 3, so there is no api call
					#logSpinData(IN_TOP_THREE)

					#Generate the body data
					gameInfo =

						type: "slotTournament"
						serialNumber: generateSerialNumber()
						entry: sessionId

					bodyData = JSON.stringify gameInfo

					apiHTTPRequest "/api/eventnotification/chedda/add", params.appToken, params.apiKey, logSpinData(IN_TOP_THREE), bodyData, true

	generateSerialNumber = () ->

		#Use the tournament ID to generate a serial number
		if tournamentId > 99999

			#If the tournament ID won't fit in the serial number, throw an error!
			throw "ERROR: Tournament ID of " + tournamentId + " is more than 5 characters!"

		#Also give a warning if the tournament number is getting uncomfortably close to the maximum
		if tournamentId >= 99900

			console.warn "WARNING: Tournament ID of " + tournamentId + " is close to maximum ID of 99999!"

		#Generate the serial number string
		serialString = "KS"

		#Determine the number of 0s that need to be added to the number
		zerosToAdd = 5 - tournamentId.toString().length

		#If we do have zeros to add, add them!
		for i in [0...zerosToAdd]

			serialString += "0"

		return serialString + tournamentId.toString()


	logSpinData = (apiResponse) ->

		if not apiResponse or (apiResponse != NO_API and apiResponse != IN_TOP_THREE and apiResponse.status != API_TIMEOUT and (apiResponse.status < 200 or apiResponse.status > 299))

			#If this is the last spin and we got a bad API call, add to the return message
			messageAppend = "-API-failure"

			console.warn "spin-API-failure: " + JSON.stringify apiResponse

		else if typeof apiResponse != "string" and apiResponse.status != API_TIMEOUT

			try 
				# We need to do some special parsing to get the id
				toParse = apiResponse.data
				toParse = "{" + toParse.slice(toParse.indexOf("\"id\""), toParse.indexOf(",", toParse.indexOf("\"id\""))) + "}"

				spinData.eventId = (JSON.parse toParse).id

				if !spinData.eventId and spinData.eventId != 0

					#There was no event id!
					console.warn "spin-API-no-id"

					messageAppend = "-API-no-id"

			catch e

				console.warn "API JSON from /api/wheels/3/addSpinEvent not good\nError: " + e.toString() + "\nRaw data: " + apiResponse.data

				messageAppend = "-API-bad-data"

		if apiResponse == IN_TOP_THREE

			#We are in the top 3! Append a special message
			messageAppend = "-in-top-three"

		if apiResponse and apiResponse.status == API_TIMEOUT

			messageAppend = "-API-timeout"

			console.warn "spin-API-timeout after " + serverAPITimeout + "ms"

		#Push the spin offsets and FS triggers into buffers
		offBuffer = new Buffer(spinData.offsets.length * 2 + 1)
		fsBuffer = new Buffer(BUFSIZE_FS)

		#Do some clever bit-shifting to create a byte that contains both the version number (2) and the number of offsets there are in the buffer
		versionAndCount = 2 #00000010
		versionAndCount << 4 #00100000
		
		#The number of reels is previously capped to 5, so we don't have to worry about overflow here
		versionAndCount |= spinData.offsets.length #00100101 (example if there are 5 offsets)
		
		#Get the version:
		#	version = versionAndCount >> 4;
		#Get the number of offsets:
		#	offsets = versionAndCount & 0x0F;
		
		offBuffer.writeUInt16BE(versionAndCount,-1, true)

		#Write the offsets
		for i in [0..spinData.offsets.length-1]

			offBuffer.writeUInt16BE(spinData.offsets[i], i*2 + 1)

		#If we got an fsTrigger but the free spin state is not turned on then we are using an outdated paradigm 
		if spinData.state.fsTrigger and not spinData.state.fsOn

			throw "Invalid Free Spin Setup!"

		#Write the fs triggers
		if spinData.state.fsOn then fsBuffer.writeUInt16BE(1, -1, true) else fsBuffer.writeUInt16BE(0, -1, true)

		if spinData.state.fsSpinsLeft then fsBuffer.writeUInt16BE(spinData.state.fsSpinsLeft, 1) else fsBuffer.writeUInt16BE(0, 1)

		if spinData.state.fsSpinsTotal then fsBuffer.writeUInt16BE(spinData.state.fsSpinsTotal, 3) else fsBuffer.writeUInt16BE(0, 3)

		if spinData.state.fsMxTotal then fsBuffer.writeUInt16BE(spinData.state.fsMxTotal, 5) else fsBuffer.writeUInt16BE(0, 5)

		if spinData.state.fsWinTotal then fsBuffer.writeUInt32BE(spinData.state.fsWinTotal, 7) else fsBuffer.writeUInt32BE(0, 7)

		getFSWildBits(spinData.state.fsWildSymbol).copy(fsBuffer, 11)

		#Insert the data from our spin into the slot log
		sql = "INSERT INTO Log_? SET SessionID=?,Gen=?,GameData=?,SpinsLeft=?,SpinsTotal=?,SecsLeft=?,SecsTotal=?,WinCurrent=?,WinTotal=?,CreateTime=?,ReelOffsets=?,FSTriggers=?"

		#While we are pushing arguments here, also add data to the buffer for storage in memcache
		argsBuffer = new Buffer(BUFSIZE_LOG)

		args = []

		args.push tournamentId
		
		args.push sessionId

		args.push gen
		argsBuffer.writeUInt32BE(gen, 0)

 		#Only log the game data if we are set to log it
		if serverLogDebug
			args.push JSON.stringify(spinData)
		else
			args.push null

		args.push spinData.state.spinsLeft
		#If we are finishing the game in a free spin state, the spins left number will be -1. In this case just input 0
		argsBuffer.writeUInt16BE((if spinData.state.spinsLeft >= 0 then spinData.state.spinsLeft else 0), 4)

		args.push spinData.state.spinsTotal
		argsBuffer.writeUInt16BE(spinData.state.spinsTotal, 6)

		args.push secsLeft
		#Again, if finishing in a free spins state the seconds left may be negative
		argsBuffer.writeUInt16BE((if secsLeft >= 0 then secsLeft else 0), 8)

		args.push spinData.state.secsTotal
		argsBuffer.writeUInt16BE(spinData.state.secsTotal, 10)

		args.push spinData.spin.wins.pay

		args.push spinData.state.winTotal
		argsBuffer.writeDoubleBE(spinData.state.winTotal, 12)

		args.push getCurrentDate().getTime()

		args.push offBuffer

		args.push fsBuffer
		fsBuffer.copy(argsBuffer, 20)

		#Create the key for the memcache insert out of the tournament and session IDs
		mcKey = "l" + tournamentId + ":" + sessionId

		#Delete the offsets from the response object, we don't need to return them
		delete spinData.offsets

		spinData.state.secsLeft = secsLeft
		
		DatabaseWrite.writeToSQL(dynamicWritePools[sessionId % dynamicCount], sql, args, 0, ($err, $res) ->
			
			if ($err)
				
				msg = badTableCheck($err) + 'spin-fail-log-insert'
	
				console.error msg + ": " + $err

				endComm 0, msg
			
			else
				
				DatabaseWrite.writeToMC(mcClient, mcKey, argsBuffer, { flags: memcachedFlags.LOG_DATA, exptime: secsLeft + 10 }, 0, ($err, $res) ->
					
					if ($err)
					
						msg = 'spin-fail-mem-insert'
	
						console.error msg + ": " + $err
		
						endComm 0, msg
					
					else
						member = sessionId + ":" + playerId
				
						DatabaseWrite.writeToRedis("ZADD", redisClient, tournamentId, spinData.state.winTotal, member, 0, ($err, $res) ->
							
							if ($err)
							
								#Log that there was a problem and continue (Should inform Kizzang of error here)
								console.log "spin-leaderboard-failure: " + $err
								
							getRanks()
							)
					)
			)

	#Gets the relevant player ranks
	getRanks = ->

		getNeighbors playerId, tournamentId, winTotal, (neighborsData) ->

			if typeof neighborsData == "string"

				endComm 1, "spin-ok-leaderboard-fail" + neighborsData + messageAppend, spinData

			else

				spinData.neighbors = neighborsData

				endComm 1, "spin-ok" + messageAppend, spinData


	checkTournament()

###
	Gets the requested number of historical scores, starting with the player's score in their current tournament (if they are in a tournament)
###
onScores = (params, response) ->

	#Send a response and close the socket
	hasEnded = false

	endComm = ($ok,$msg,$response) ->

		if not hasEnded then response.send (new ProtocolServer($ok,$msg,{command: 'scores', params:params},$response)).out()

		hasEnded = true

	conn = null

	pastTournaments = null

	#First verify out parameters
	if not params or not params.playerId or not params.date

		endComm 0, 'scores-fail-null-params'
		return


	getHistoricTournaments = ->

		#First get the tournaments we need to check
		sql = "SELECT TournamentList FROM Players WHERE PlayerID=?"

		args = [ params.playerId ]

		staticReadPool.query sql, args, ($err, $backData) ->

			if $err or not $backData[0]

				msg = badTableCheck($err) + "scores-fail-invalid-player"

				console.log msg + ": " + $err

				endComm 0, msg

			else

				#Parse the tournaments
				pastTournaments = JSON.parse($backData[0].TournamentList)

				#Get the scores associated with these tournaments
				getHistoricScores()

	getHistoricScores = ->

		#An object that holds an array of objects
		pastScores =
			tournaments: []

		#Exit if there isn't any data for the requested date
		if not pastTournaments[params.date]

			endComm 0, "scores-fail-invalid-date"
			return

		#Because CoffeeScript, we save the length separately
		listLength = pastTournaments[params.date].length - 1

		#Generate a query string
		sql = ""
		args = []

		for i in [0..listLength]

			sql += "SELECT SessionID, StartTime, Token FROM Session_? WHERE PlayerID=? "

			args.push pastTournaments[params.date][i]
			args.push params.playerId

			if i != listLength
				sql += "UNION "

		sql += "ORDER BY StartTime DESC"

		staticReadPool.query sql, args, ($err, $backData) ->

			if $err

				msg = badTableCheck($err) + "scores-fail-select-scores-error"

				console.log msg + ": " + $err

				endComm 0, msg

			else

				#Get the offset if it was given to us (default 0)
				offset = 0

				if params.offset

					offset = params.offset

				#Always return 10 objects
				sessionInfo = $backData.slice(offset, offset+10)

				if sessionInfo.length == 0

					endComm 0, "score-fail-no-scores"
					return

				#Alter the returned data slightly
				finishedCount = 0
				for i in [0..sessionInfo.length - 1]

					#Edit the date returned to us
					sessionInfo[i].StartTime = new Date(sessionInfo[i].StartTime).toString()

					#Add the tournament ID to the session info object (get it from the token)
					sessionInfo[i].TournamentID = parseInt(sessionInfo[i].Token.slice(0, sessionInfo[i].Token.indexOf(':')))

					#Get the score from each session, this operation is O(1) so calling it 10 times should be fine
					member = sessionInfo[i].SessionID + ":" + params.playerId

					#Delete the Token and the session ID from session Info
					delete sessionInfo[i].Token
					delete sessionInfo[i].SessionID

					getScore = (index) ->

						redisClient.ZSCORE sessionInfo[i].TournamentID.toString(), member, ($err, $res) ->

							if $err

								console.log "scores-fail-get-score-error: " + $err

								#Mark an error
								finishedCount = 10

							else

								#Add the score to the returned data
								sessionInfo[index].WinTotal = $res

								if ++finishedCount == sessionInfo.length

									#Give different messages if we have reached the end of the list or not
									if sessionInfo.length < 10
										endComm 1, "scores-ok-end-of-list", sessionInfo
									else
										endComm 1, "scores-ok", sessionInfo

								else if finishedCount > sessionInfo.length

									#If the finish count is higher than the number of sessions, we had an error
									endComm 0, "scores-fail-get-score-error"
					getScore i

	getHistoricTournaments()

onWinners = (params, response) ->
	#Send a response and close the socket
	endComm = ($ok,$msg,$response) ->

		response.send (new ProtocolServer($ok,$msg,{command: 'bcommand/onWinners', params:params},$response)).out()

	curDate = getCurrentDate()

	numPlaces = 10 #The number of top places we will return

	topScore = null

	#First verify out parameters
	if not params or not params.tournamentId

		endComm 0, 'winners-fail-null-params'
		return


	checkTournament = ->

		#Make sure that the tournament we are getting the winners from has expired
		sql = "SELECT EndDate FROM SlotTournament WHERE ID=? AND EndDate<?"

		args = [ params.tournamentId, curDate ]

		staticReadPool.query sql, args, ($err, $backData) ->

			#If we didn't get anything back then either the tournament doesn't exist, or it hasn't expired
			if $err or not $backData[0]

				msg = badTableCheck($err) + "winners-fail-invalid-tournament"

				console.log msg + ": " + $err

				endComm 0, msg

			else

				getTopPlayers()

	getTopPlayers = ->
		#Get the top players in descending order
		redisClient.ZREVRANGEBYSCORE params.tournamentId.toString(), "+inf", "-inf", "WITHSCORES", "LIMIT", 0, numPlaces, ($err, $res) ->

			if $err or $res.length == 0

				console.log "winners-fail-top-players: " + $err

				endComm 0, "winners-fail-top-players"
				return

			else
				console.log "top player returns: " + $res.length
				topLeft = $res.length / 2

				#Loop through the top players, creating an object
				winners = []
				pushObject = null
				for i in [0..($res.length) - 1]

					if (i % 2) == 0

						#Create a new push object every even value
						pushObject = new Object

						#Even values are player IDs
						pushObject.PlayerID = extractRedisMember($res[i])[1]

						screenNameKey = "p" + pushObject.PlayerID.toString()

						getMemcachedData(screenNameKey, (($err, $res, $index)->

							if $err or !$res

								msg = badTableCheck($err) + "winners-fail-data-missing"

								console.log msg + ": " + $err

								endComm 0, msg

							else
							
								pushIndex = $index / 2

								if winners[pushIndex]

									winners[$index / 2].ScreenName = $res.ScreenName

									#Only add the facebook ID if it exists
									if ($res.FacebookID and $res.FacebookID != "")
										winners[$index / 2].FacebookID = $res.FacebookID

									if --topLeft == 0

										if params.playerId then getRank()

										else endComm 1, 'winners-ok', {winners:winners}

								else

									winners[pushIndex] = {ScreenName: $res}), i)

					else

						#Odd values are scores
						pushObject.WinTotal = $res[i]

						#Add the push object every odd value
						pushIndex = Math.floor(i / 2)

						if winners[pushIndex]

							winners[pushIndex].PlayerID = pushObject.PlayerID

							winners[pushIndex].WinTotal = pushObject.WinTotal

							if --topLeft == 0

								if params.playerId then getRank()

								else endComm 1, 'winners-ok', {winners:winners}

						else

							winners[Math.floor(i / 2)] = pushObject

	checkTournament()

###
	Called by the client to determine if the provided player is currently playing a game.
	If they are playing a game then the ID of the game they are playing will be returned.
###
onCheckPlayer = (params, response) ->

	#Send a response and close the socket
	hasEnded = false

	endComm = ($ok,$msg,$response)->

		if not hasEnded then response.send (new ProtocolServer($ok,$msg,{command: 'command/checkPlayer', params:params},$response)).out()

		hasEnded = true

	if not params or not params.playerId

		endComm 0, "checkPlayer-fail-null-params"

		return

	curDate = getCurrentDate() #The time when this command is made

	returnObj = { inGame: false }

	token = ""

	sessionId = ""

	tournament = null

	startTime = null

	gameId = null

	state = {}

	#Check if the requested player exists in the database yet
	checkPlayer = ->
		
		sql = "SELECT Token, SessionID, TournamentList, ScreenName, FacebookID FROM Players WHERE PlayerID=?"

		args = [ params.playerId ]

		staticReadPool.query sql, args, ($err, $backData) ->

			if $err

				msg = badTableCheck($err) + "regToken-fail-playerCheck"

				console.log msg + ": " + $err

				endComm 0, "regToken-fail-playerCheck"

			else
				#If we did not find the player, they are not playing a game
				if not $backData[0]

					endComm 1, "checkPlayer-success-no-game", returnObj

				else #If we found the player, then we need to check their tournament and session before continuing

					token = $backData[0].Token

					sessionId = $backData[0].SessionID

					getSessionInfo()

	#Check that the player's current session is has timed out
	getSessionInfo = ->

		#We need to extract the tournament ID from the token
		tournament = getTournamentFromToken(token)

		#First check how much time we have remaining, also get the old gameID while we are at it

		sql = "SELECT StartTime, GameID FROM Session_? WHERE SessionID=?"

		args = [ tournament, sessionId ]

		staticReadPool.query sql, args, ($err, $backData) ->

			if $err or not $backData[0]

				#If this check fails the player will be allowed through, so mark that the player isn't in a game
				endComm 1, "checkPlayer-success-no-sessionData", returnObj

			else

				startTime = parseInt $backData[0].StartTime

				gameId = parseInt $backData[0].GameID

				mcKey = "l" + tournament + ":" + sessionId

				#First search memcached for the data
				getMemcachedData mcKey, ($err, $res) ->

					if not $res

						#If we didn't get back any data, then we haven't played yet and need to get data from the games themselves

						#Get the game data
						info = getGameInfo gameId.toString()

						state.secsTotal = info.SecsTotal

						state.spinsTotal = state.spinsLeft = info.SpinsTotal

						calculateTimeRemaining()

					else

						state.secsTotal = $res.SecsTotal

						state.spinsTotal = $res.SpinsTotal

						state.spinsLeft = $res.SpinsLeft

						calculateTimeRemaining()

	#Helper function that gets game data
	getGameInfo = (id) ->

		if gameData[id]

			return gameData[id]

		else

			#No data was found, try mySQL
			sql = "SELECT * FROM SlotGame WHERE ID=?"

			args = [parseInt id]

			staticReadPool.query sql, args, ($err, $backData) ->

				if $err or not $backData[0]

					msg = badTableCheck($err) + "checkPlayer-fail-game-not-found"

					console.log msg + ": " + $err

					endComm 0, msg

				else

					#Populate!
					populateGames $backData[0]

					return $backData[0]

	calculateTimeRemaining = ->

		timeRemaining = state.secsTotal - (common.secondsBetween (new Date(startTime)), curDate)

		state.secsLeft = timeRemaining

		if timeRemaining <= 0

			#If we ran out of time, we can try to re-register
			endComm 1, "checkPlayer-success-outOfTime", returnObj

		else

			#If we haven't run out of time, we need to see if we have run out of spins
			checkSessionSpins()

	checkSessionSpins = ->

		if state.spinsLeft == null or state.spinsLeft > 0

			#There are spins left! We are currently in a game
			returnObj.inGame = true
			returnObj.gameId = gameId
			endComm 1, "checkPlayer-success-in-game", returnObj

		else

			#If we ran out of spins, we can try to re-register
			endComm 1, "checkPlayer-success-outOfSpins", returnObj

	checkPlayer()


###
	Called only by the Kizzang back end to register a specific user with a tournament
	and create a new session.
	Will send a response with the user's unique session token. If the user requested
	already has a token, it respond with that key as well as a special message.
###
onRegToken = (params, response) ->

	#Send a response and close the socket
	hasEnded = false

	endComm = ($ok,$msg,$response)->

		if not hasEnded then response.send (new ProtocolServer($ok,$msg,{command: 'bcommand/regToken', params:params},$response)).out()

		hasEnded = true


	#First verify that we were given Parameters
	if not params or not params.tournamentId or not params.gameId or not params.playerId

		endComm 0, 'regToken-fail-null-params'

		return

	if not params.screenName

		#If no screen name was included, make it an empty string
		params.screenName = "Anonymous";

	if not params.fbId

		#Default the facebook ID to the empty string
		params.fbId = "";

	if not params.appToken

		endComm 0, 'regToken-fail-no-appToken'

		return

	if not params.apiKey

		endComm 0, "regToken-fail-no-apiKey"

		return

	curDate = getCurrentDate() #The time when this command is made

	#Get a string of the current date
	dateString = curDate.getFullYear() + "-" + (curDate.getMonth()+1) + "-" + curDate.getDate()

	oldToken = null #The old token the player was using

	newToken = null #The randomly generated play token

	oldTournament = null

	tournamentId = null #The player's tournament ID

	oldSessionId = null #The old session ID

	sessionId = null #The ID of the new session

	playerExists = null #If the given player exists or not

	tournamentList = null

	startTime = null

	gameId = params.gameId

	oldGameId = null

	#Current Game data

	state =

		spinsLeft: null

		spinsTotal: null

		secsLeft: null

		secsTotal: null

		winTotal: 0


	#Check if the requested player exists in the database yet
	checkPlayer = ->

		sql = "SELECT Token, SessionID, TournamentList, ScreenName, FacebookID FROM Players WHERE PlayerID=?"

		args = [ params.playerId ]

		staticReadPool.query sql, args, ($err, $backData) ->

			if $err

				msg = badTableCheck($err) + "regToken-fail-playerCheck"

				console.log msg + ": " + $err

				endComm 0, msg

			else
				#If we did not find the player, skip to verifying the tournament that they are trying to enter
				if not $backData[0]

					playerExists = false

					verifyTournament params.tournamentId, ($isGood) ->

						if $isGood
							#If the check succeeds then create a new token
							createNewToken()
						else
							endComm 0, "regToken-fail-invalid-tournament_1"

				else #If we found the player, then we need to check their tournament and session before continuing

					playerExists = true

					oldToken = $backData[0].Token

					oldSessionId = $backData[0].SessionID

					tournamentList = JSON.parse($backData[0].TournamentList)

					# Update the screen name if required
					updateScreenName($backData[0].ScreenName, $backData[0].FacebookID)

	#Updates the player's screen name
	updateScreenName = (oldScreenName, oldFacebookID)->
		
		#Determine what needs to be added based on what is available
		sql = "UPDATE Players SET"

		args = new Array()

		# We also need to update our screen name data
		nameKey = "p" + params.playerId
		fbKey = "f" + params.playerId
		memName = oldScreenName
		memFb = oldFacebookID

		needNameChange = false
		needFBChange = false

		if (!isEmpty(params.screenName) and params.screenName != oldScreenName and params.screenName != "Anonymous")
			needNameChange = true

		if (!isEmpty(params.fbId) and params.fbId != oldFacebookID)
			needFBChange = true

		if  needNameChange

			sql += " ScreenName=?"

			args.push params.screenName

			memName = params.screenName

			if needFBChange

				#We need to add a comma if the facebook Id is also going to be included
				sql += ","

		if needFBChange

			sql += " FacebookID=?"

			args.push params.fbId.toString()

			memFb = params.fbId.toString()
	
		sql += " WHERE PlayerID=?"

		args.push params.playerId

		if !needNameChange and !needFBChange

			#If we don't need to change anything, skip the write!
			getSessionInfo()

		else

			DatabaseWrite.writeToSQL staticWritePool, sql, args, 0, ($err, $backData) ->

				if $err

					msg = badTableCheck($err) + "regToken-fail-screenName-update"

					console.warn msg + ": " + $err

					endComm 0, msg

				else
					
					numberUpdated = 0
					if (!needNameChange || !needFBChange)
						
						numberUpdated++
					
					# Update memcached
					if (needNameChange)
						DatabaseWrite.writeToMC mcClient, nameKey, memName, { flags: memcachedFlags.SCREEN_NAME, exptime: screenNameExp }, 0, ($err, $res) ->
							
							#Errors are fatal!
							if $err 
								
								msg = "regToken-fail-screenName-mem-update"
								
								console.warn msg + $err
								
								endComm 0, msg
							
							else
								
								numberUpdated++
								console.log(numberUpdated)
								if (numberUpdated >= 2)
								
									getSessionInfo();	
							
					if (needFBChange)
						
						DatabaseWrite.writeToMC mcClient, fbKey, memFb, { flags: memcachedFlags.FACEBOOK_ID, exptime: screenNameExp }, 0, ($err, $res) ->
	
							#Log to the console on error
							if $err
							
								msg = "regToken-fail-facebook-mem-update"
						
								console.warn msg + $err
								
								endComm 0, msg
							
							else
								
								numberUpdated++
								console.log(numberUpdated)								
								if (numberUpdated >= 2)
								
									getSessionInfo();	

	#Check that the player's current session is has timed out
	getSessionInfo = ->

		#We need to extract the tournament ID from the token
		oldTournament = getTournamentFromToken(oldToken)

		#First check how much time we have remaining, also get the old gameID while we are at it

		sql = "SELECT StartTime, GameID FROM Session_? WHERE SessionID=?"

		args = [ oldTournament, oldSessionId ]

		staticReadPool.query sql, args, ($err, $backData) ->

			if $err or not $backData[0]
				#If this check fails, let the player throgh to prevent them from being permanently locked out
				verifyTournament params.tournamentId, ($isGood) ->

					if $isGood

						createNewToken()
					else
						msg = badTableCheck($err) + "regToken-fail-invalid-tournament_2"

						console.log msg + ": " + $err

						endComm 0, msg

			else

				startTime = parseInt $backData[0].StartTime

				oldGameId = parseInt $backData[0].GameID

				if state.secsTotal != null

					calculateTimeRemaining()


		mcKey = "l" + oldTournament + ":" + oldSessionId

		#First search memcached for the data
		getMemcachedData mcKey, ($err, $res) ->

			if not $res

				#If we didn't get back any data, then we haven't played yet and need to get data from the games themselves

				#Get the game data
				info = getGameInfo gameId.toString()

				state.secsTotal = state.secsLeft = info.SecsTotal

				state.spinsTotal = state.spinsLeft = info.SpinsTotal

				if startTime != null

					calculateTimeRemaining()

			else

				#We found data!
				state.secsLeft = $res.SecsLeft

				state.secsTotal = $res.SecsTotal

				state.spinsLeft = $res.SpinsLeft

				state.spinsTotal = $res.SpinsTotal

				state.winTotal = $res.WinTotal

				extractFSTriggers $res.FSTriggers, state

				if startTime != null

					calculateTimeRemaining()

	#Helper function that gets game data
	getGameInfo = (id) ->

		if gameData[id]

			return gameData[id]

		else

			#No data was found, try mySQL
			sql = "SELECT * FROM SlotGame WHERE ID=?"

			args = [parseInt id]

			staticReadPool.query sql, args, ($err, $backData) ->


				if $err or not $backData[0]

					msg = badTableCheck($err) + "regToken-fail-game-not-found"

					console.log msg + ": " + $err

					endComm 0, msg

				else

					#Populate!
					populateGames $backData[0]

					return $backData[0]

	calculateTimeRemaining = ->

		timeRemaining = state.secsTotal - (common.secondsBetween (new Date(startTime)), curDate)

		state.secsLeft = timeRemaining

		if timeRemaining <= 0

			#If we ran out of time, we can try to re-register
			verifyTournament params.tournamentId, ($isGood) ->

				if $isGood
					createNewToken()
				else
					endComm 0, "regToken-fail-invalid-tournament_3"

		else

			#If we haven't run out of time, we need to see if we have run out of spins
			checkSessionSpins()

	checkSessionSpins = ->

		if state.spinsLeft == null or state.spinsLeft > 0

			#If we don't have a log we haven't spun once yet! We still have spins left
			verifyTournament oldTournament, ($isGood) ->

				if $isGood

					#If the tournament is still good, return previous data with a special message
					getNeighbors params.playerId, oldTournament, state.winTotal, (neighbors) ->

						message = null

						if typeof data == "string"

							message = "regToken-rejoin-success-leaderboard-fail"

						else

							message = "regToken-rejoin-success"

						resObject =
							playerId: params.playerId
							playToken: oldToken
							tournamentId: oldTournament
							gameId: oldGameId
							betTotal: serverBetTotal
							state: state
							neighbors: neighbors

						endComm 1, message, resObject

				else if oldTournament != params.tournamentId
					#If the tournament is not good, we can try to re-register
					verifyTournament params.tournamentId, ($isGood) ->

						if $isGood

							createNewToken()
						else

							endComm 0, "regToken-fail-invalid-tournament_3"

				else

					endComm 0, "regToken-fail-invalid-tournament_4"

		else

			#We don't have any spins remaining, attempt to join a new tournament
			verifyTournament params.tournamentId, ($isGood) ->

				if $isGood

					createNewToken()
				else

					endComm 0, "regToken-fail-invalid-tournament_5"


	#Verify the tournament ID requests
	verifyTournament = (id, verifyTournamentCallback) ->

		#Try the cache
		if tournamentData[id.toString()]

			#We found the tournament! Now check the dates
			if tournamentData[id.toString()].EndDate > curDate and tournamentData[id.toString()].StartDate < curDate

				verifyTournamentCallback(true)

			else

				#The tournament is not active
				verifyTournamentCallback(false)

		else
			#No data from cache, let's try the database!
			sql = "SELECT * FROM SlotTournament WHERE ID=?"

			args = [ id, curDate, curDate ]

			staticReadPool.query sql, args, ($err, $backData) ->

				if $err or not $backData[0]
					#We expect this check to fail every now and again
					if $err then console.log badTableCheck($err) + "regToken-verify-tournaments-fail: " + $err

					# The Tournament cannot be found
					verifyTournamentCallback(false)

				else

					# We found data, populate tournamentData
					populateTournaments $backData[0]

					#Check the dates
					if $backData[0].EndDate > curDate and $backData[0].StartDate < curDate

						verifyTournamentCallback(true)

					else

						#The tournament is not active
						verifyTournamentCallback(false)

	#Actually creates the token
	makeToken = (seed) ->

		#Generate a random token using a sha256 algorithm
		sha256 = crypto.createHash('sha256')
		sha256.update seed

		return sha256.digest('hex').toString()


	#Creates a new token
	createNewToken = ->

		#Generate a random token (Note: Math.random is not crypologically secure, but we are just using it to further differentiate seeds)
		newToken = (params.tournamentId.toString() + ":" + makeToken(process.hrtime()[1].toString() + lastPlayerId + params.tournamentId + Math.random())).slice(0, 40)

		#Once our new token is made, tell the API that we are starting a new game
		apiHTTPRequest("/api/players/" + params.playerId + "/gamecounts", params.appToken, params.apiKey, createSession, "gameType=SlotTournament")

	#Creates a new session
	createSession = (apiResponse)->
		parseData = JSON.parse apiResponse.data
		if parseInt(parseData.maxGames) < parseInt(parseData.count)
			endComm 0, "regToken-fail-max-games"
			console.warn "Max games reached"
            
		if serverRequireAPICall and (not apiResponse or apiResponse.status < 200 or apiResponse.status > 299 or apiResponse.status == API_TIMEOUT)

			if not apiResponse or (apiResponse and apiResponse.status != API_TIMEOUT)

				endComm 0, "regToken-fail-API-failure"

				console.warn "regToken-fail-API-failure: " + apiResponse

			else

				endComm 0, "regToken-fail-API-timeout"

				console.warn "regToken-fail-API-timeout after " + serverAPITimeout + "ms"

			return

		#If we are creating a new session, the seconds and spins left needs to be equal to their total values in the original game data
		info = getGameInfo gameId.toString()

		state.secsLeft = state.secsTotal = info.SecsTotal

		state.spinsLeft = state.spinsTotal = info.SpinsTotal



		#Create the new session
		sql = "INSERT INTO Session_? (Token, PlayerID, GameID, StartTime) VALUES (?, ?, ?, ?)"

		args = [ params.tournamentId, newToken, params.playerId, gameId, curDate.getTime() ]
		
		DatabaseWrite.writeToSQL staticWritePool, sql, args, 0, ($err, $backData) ->

			if $err

				msg = badTableCheck($err) + "regToken-fail-insert-session"

				console.log msg + ": " + $err

				endComm 0, msg

			else
				sessionId = $backData.insertId

				#Create the session in Memcached, and make it expire shortly after the game is to end
				argsBuffer = new Buffer(28)

				argsBuffer.writeDoubleBE(parseInt(sessionId), 0)
				argsBuffer.writeDoubleBE(parseInt(params.playerId), 8)
				argsBuffer.writeUInt32BE(parseInt(gameId), 16)
				argsBuffer.writeDoubleBE(parseInt(curDate.getTime()), 20)

				mcKey = "s" + newToken

				#Make sure we do not set a negative or 0 expiration
				if state.secsTotal <= 0 then state.secsTotal = 1

				DatabaseWrite.writeToMC mcClient, mcKey, argsBuffer, { flags: memcachedFlags.SESSION_DATA, exptime: state.secsTotal + 10 }, 0, ($err, $res) ->
						
					if ($err)
					
						msg = "regToken-fail-mem-error"
						
						console.warn(msg, $err)
						
						endComm 0, msg
						
					else

						#Add our player to the leaderboard only if they are not already on it
						member = sessionId + ":" + params.playerId
						
						DatabaseWrite.writeToRedis "ZINCRBY", redisClient, params.tournamentId.toString(), 0, member, 0, ($err, $res) ->
		
							if $err
		
								console.log "regToken-fail-register-to-leaderboard: " + $err
		
								endComm 0, "regToken-fail-register-to-leaderboard"
		
							else
		
								#Insert a new player, or update an existing one
								if not playerExists
									insertPlayer()
								else
									updatePlayer()


	#Update an existing player
	updatePlayer = ->

		sql = "UPDATE Players SET TournamentID=?, Token=?, SessionID=?, TournamentList=? WHERE PlayerID=?"

		#Check if the current date and the requested tournament has been used yet
		if not tournamentList[dateString]

			#No tournaments for the current date, add the current one
			tournamentList[dateString] = [params.tournamentId]

		else if tournamentList[dateString].indexOf(params.tournamentId) == -1

			#We have tournaments for this day, but not the tournament we are currently joining
			tournamentList[dateString].push params.tournamentId

		tournamentList = JSON.stringify tournamentList

		args = [ params.tournamentId, newToken, sessionId, tournamentList, params.playerId ]
		
		DatabaseWrite.writeToSQL staticWritePool, sql, args, 0, ($err, $backData) ->

			if $err
				#If there is an error here, we should try to delete the session for cleanup
				#If this delete fails nothing will break too horribly
				DatabaseWrite.writeToSQL staticWritePool, "DELETE FROM Session_? WHERE SessionID=?", [ params.tournamentId, sessionId ], 0, ($err, $res) ->

				msg = badTableCheck($err) + "regToken-fail-update-player"

				console.log msg + ": " + $err

				endComm 0, msg

			else

				sendReturn("update")


	#Insert a new player into the players table
	insertPlayer = ->

		sql = "INSERT INTO Players (PlayerID, ScreenName, TournamentID, Token, SessionID, TournamentList, FacebookID) VALUES (?, ?, ?, ?, ?, ?, ?)"

		#Create a new TournamentList object
		newList = {}

		newList[dateString] = [params.tournamentId]

		args = [ params.playerId, params.screenName, params.tournamentId, newToken, sessionId, JSON.stringify(newList), params.fbId ]

		DatabaseWrite.writeToSQL staticWritePool, sql, args, 0, ($err, $backData) ->

			if $err
				#If there is an error here, we need to delete the session data
				#Again, this failing isn't so bad, but we should try to do it anyway
				DatabaseWrite.writeToSQL staticWritePool, "DELETE FROM Session_? WHERE SessionID=?", [ params.tournamentId, sessionId ], 0, ($err, $res) ->

				msg = badTableCheck($err) + "regToken-fail-insert-player"

				console.log msg + ": " + $err

				endComm 0, msg

			else

				#Once added to mySQL, add the player's screen name and facebook ID to memcached
				nameKey = "p" + params.playerId

				DatabaseWrite.writeToMC mcClient, nameKey, params.screenName, { flags: memcachedFlags.SCREEN_NAME, exptime: screenNameExp }, 0, ($err, $res) ->

					#Log to the console on error
					if $err 
						
						msg = "regToken-fail-mem-fail-2"
						
						console.warn msg, $err
						
						endComm 0, msg

					#Only add the facebook ID if there is a facebook ID to add
	
					else if (!isEmpty(params.fbId))
	
						fbKey = "f" + params.playerId
	
						DatabaseWrite.writeToMC mcClient, fbKey, params.fbId, { flags: memcachedFlags.FACEBOOK_ID, exptime: screenNameExp }, 0, ($err, $res) ->
	
							#Log to the console on error
							if $err 
								
								msg = "regToken-fail-mem-fail-3"
								
								console.warn msg, $err
								
								endComm 0, msg
								
							else
								
								sendReturn("insert")
					else

						sendReturn("insert")

	sendReturn = (type) ->
		
		getNeighbors params.playerId, params.tournamentId, state.winTotal, (neighbors) ->
		
			message = null
	
			if typeof data == "string"
	
				message = "regToken-success-" + type + "-leaderboard-fail"
	
			else
	
				message = "regToken-success-" + type
	
			endComm 1, message, { playerId: params.playerId, playToken: newToken, tournamentId: params.tournamentId, gameId: gameId, betTotal: serverBetTotal, state, neighbors }

	checkPlayer()

#Used to get the current time of active servers in order to diagnose timing issues

onTiming = (params, response) ->

	#Send response and close everything
	hasEnded = false

	endComm = ($ok,$msg,$response)->

		if not hasEnded then response.send (new ProtocolServer($ok,$msg,{command: 'timing', params:params},$response)).out()

		hasEnded = true

	#The maximum number of servers in the history that we will try to get the current time of defaults to 100 if no parameters provided
	queryLimit = (if params and params.queryLimit then params.queryLimit else 100)

	retObject = {servers: []}

	#Query the server list for the server host, ports, and starting time
	sql = "SELECT Host, Port, StartDate FROM SlotServer ORDER BY StartDate DESC LIMIT ?"

	args = [parseInt queryLimit]

	staticReadPool.query sql, args, ($err, $backData) ->

		if $err or $backData.length == 0

			msg = badTableCheck($err) + "timing-fail-SlotServer-error"

			console.log msg + ": " + $err

			endComm 0, msg

		else

			#We will attempt to make connections to each server found, and we will store the data from the servers that return information (are running)
			queriedServers = {} #Object that holds data for servers that have already been queried

			queriesRemaning = $backData.length

			for i in [0..$backData.length - 1]
				#First make sure we haven't already queried a server with this data
				serverString = $backData[i].Host + ":" + $backData[i].Port
				if queriedServers[serverString]

					if --queriesRemaning == 0
						finishOperation()

					continue

				#The data the field holds doesn't matter, only the field name
				queriedServers[serverString] = true

				#The server connection options
				options =
					host: $backData[i].Host
					port: $backData[i].Port
					path: "/scommand/timingConnect"
					method: "POST"
					headers: { 'content-type': 'application/x-www-form-urlencoded' }


				#Include the required password for inter-server communications, as well as data that we will get back
				extraData = { data: JSON.stringify({password: "m9qcnr984x98rm23jnr82189cnuvt1hc89rcnh418xm9rc4jhn18", host: options.host, port: options.port}) }

				#Send the response
				req = http.request options, (response) ->

					dataHold = ""

					response.on 'data', (data) ->
						dataHold += data

					response.on 'end', ->

						serverObj = JSON.parse dataHold

						retObject.servers.push serverObj

						if --queriesRemaning == 0
							finishOperation()



				req.on 'error', (error) ->

					#Simply reduce the number of queries remaining
					if --queriesRemaning == 0
						finishOperation()

				req.write urlencoder.encode(extraData)

				req.end()

	finishOperation = ->

		endComm 1, "timing-success", retObject


onTimingConnect = (params, response) ->

	params.date = new Date().toString()
	delete params.password

	response.send JSON.stringify(params)

onOldTournaments = (params, response) ->

	#Send response and close everything
	hasEnded = false

	endComm = ($ok,$msg,$response)->

		if not hasEnded then response.send (new ProtocolServer($ok,$msg,{command: 'oldTournaments', params:params},$response)).out()

		hasEnded = true

	#We don't need to check for parameters because we only expect an offset and if we get no offset then we assume no offset

	offset = params.offset ? 0

	curDate = getCurrentDate()

	resPerPage = 10

	getTournaments = ->
		#Get the data for all our tournaments ordered by date. It's messy, but we don't care about efficiency for this one
		sql = "SELECT * FROM SlotTournament WHERE EndDate < ? ORDER BY EndDate DESC"

		args = [curDate, offset + resPerPage]

		staticReadPool.query sql, args, ($err, $backData) ->

			if $err

				msg = badTableCheck($err) + "oldTournaments-fail-table-error"

				console.error msg + ": " + $err

				endComm 0, msg

			else if $backData.length == 0

				#There are no old tournaments. This is not an error
				endComm 1, "oldTournaments-ok-no-tournaments"

			else

				generateReturnData $backData

	generateReturnData = (data) ->

		#Bound check!
		returnMessage = "oldTournaments-ok" #If the returned values are at the end of the list, we return a special message

		if data.length - 1 < offset

			#Bad offset!
			endComm 0, "oldTournaments-fail-out-of-bounds-offset", { maxOffset: data.length - 1 }

			return

		if data.length <= offset + resPerPage

			#We are at the final page!
			returnMessage = "oldTournaments-ok-end-of-list"

		#Simply slice the array based on the offset and results per page!
		retArray = data.slice(offset, offset + resPerPage) 

		#Loop through the array and pretty up the dates
		for i in [0..retArray.length - 1]

			retArray[i].StartDate = new Date(retArray[i].StartDate).toString()

			retArray[i].EndDate = new Date(retArray[i].EndDate).toString()

		endComm 1, returnMessage, { tournaments: retArray }


	getTournaments()


#Receive data from socket

onData = (command, params, response) ->

	#First make sure we have a command
	response.send (new ProtocolServer 0, 'server-null-command').out() if not command

	#Run through commands
	switch command

		when 'assets' then onAssets params, response

		when 'join' then onJoin params, response

		when 'spin' then onSpin params, response

		when 'times' then onTimes response #This command does not require any parameters

		when 'games' then onGames response #This command does not require any parameters

		when 'list' then onList params, response

		when 'lobby' then onLobbyList response

		when 'rank' then onRank params, response

		when 'ranks' then onRanks params, response

		when 'scores' then onScores params, response

		when 'checkPlayer' then onCheckPlayer params, response

		#If we do not have a valid command, make an invalid-command response
		else response.send (new ProtocolServer 0, 'server-invalid-command', { command: command, params: params}).out()


# Special onData function used when getting data through the backdoor path (bcommand)

onBackdoorData = (command, params, response) ->

	#First make sure we have a command
	response.send (new ProtocolServer 0, 'server-null-command').out() if not command

	#Run through commands
	switch command

		when 'regToken' then onRegToken params, response

		when 'winners' then onWinners params, response

		when "timing" then onTiming params, response

		when "oldTournaments" then onOldTournaments params, response

		#If we do not have a valid command, make an invalid-command response
		else response.send (new ProtocolServer 0, 'server-invalid-command', { command: command, params: params}).out()

#Special onData function for inter-server communications

onInterServerData = (command, params, response) ->

	#First make sure we have a command
	response.send (new ProtocolServer 0, 'server-null-command').out() if not command

	#Require a special, hardcoded password for access that only the servers know
	if not params or not params.password or params.password != "m9qcnr984x98rm23jnr82189cnuvt1hc89rcnh418xm9rc4jhn18"

		response.send (new ProtocolServer 0, "interServer-invalid-password").out()

	#Run through commands
	switch command

		when 'timingConnect' then onTimingConnect params, response

		#If we do not have a valid command, make an invalid-command response
		else response.send (new ProtocolServer 0, 'server-invalid-command', { command: command, params: params}).out()



startSlotServer = ->
	console.log "STARTING SERVER"

	# set the transaction name for newrelic based on URL
	#if newrelic
	#	app.use (request, response, next) ->
	#		transactionName = if request.originalUrl? then request.originalUrl else 'Unknown'
	#		newrelic.setTransactionName(transactionName)
	#		next()

	#Before we do anything, check if we are currently "too busy"
	app.use (request, response, next) ->

		if toobusy()

			response.send 503, "server-too-busy"

		else

			next()

	# health check for elb
	app.use "/ok", (request, response) ->

		randomValue = parseInt(Math.random()*10000)
		checkKey = 'healthCheck' + randomValue.toString()

		passHealthCheck =  ->
			response.set "Content-Type", "text/html"
			response.send "OK"

		failHealthCheck = ( $msg ) ->
			console.error('Health check failed: ' + $msg); 
			response.send 500

		checkMemcacheSet = ( $msg ) ->
 
			mcClient.set checkKey, randomValue, { flags: memcachedFlags.SCREEN_NAME, exptime: 5 }, ($err, $res) ->

				if $err
					failHealthCheck "memcached set failed"
				else
					checkMemcacheGet()

		checkMemcacheGet = ( $msg ) ->
			console.log 'Check memcache get: ', checkKey, randomValue
			mcClient.get checkKey, ($err, $res) ->
				if $err or not $res
					failHealthCheck "memcached get failed " + $err
				else
					if $res[checkKey] != randomValue.toString()
						failHealthCheck "memcached get value failed " + $err
					else
						checkRedis()

		checkRedis = ( $msg ) ->


			#Verify the Redis connection
			redisClient.INFO "server", ($err, $res) ->

				if $err
					failHealthCheck "redis info failed " + $err
				else
					console.log $res
					passHealthCheck()

 	 

		# start here check database
		staticReadPool.query "SELECT * FROM SlotTournament LIMIT 1", ($qerr, $backData) ->
			if $qerr
				console.warn badTableCheck($qerr) + "Could not connect to SlotTournament mySQL ERROR"
				failHealthCheck "Bad database"
			else
				checkMemcacheSet()


	app.use "/crossdomain.xml", (request, response) ->

		#Debug out
		if serverDebug then console.warn 'crossdomain.xml REQUESTED | Host: ' + request.hostname

		#Simply return the crossdomain information
		xmlData = fs.readFile __dirname + '/www/crossdomain.xml', ($err, $data) ->

			if $err

				console.log "crossdomain Error: " + $err

			else

				response.set "Content-Type", "text/html"
				response.send $data.toString()

	#Parse for urlencoded values
	app.use bodyParser.urlencoded()

	app.use (request, response, next) ->

		gotError = false
		error = null

		#Check to make sure our JSON is good
		try
			if request.body and request.body.data
				JSON.parse request.body.data

		catch e

			#If we caught an error, the JSON is not good
			gotError = true
			error = e

		if gotError

			#The ride ends here
			if error

				#Send back the stack trace if the server is in debug bode
				if serverDebug

					response.send (new ProtocolServer 0, 'server-invalid-JSON', { stackTrace: error.stack }).out()

				else

					response.send (new ProtocolServer 0, 'server-invalid-JSON').out()

			else

				#There is no "data" or "body" field. The URL encoding must be wrong
				response.send (new ProtocolServer 0, 'server-invalid-urlencoding').out()

		else

			next()

	#Apply middleware that will read the command parameter and pass it into onData
	app.use '/command/:command', (request, response) ->

		#Debug out
		debugDumpStr = "null"
		if request.body and request.body.data
			debugDumpStr = request.body.data
		if serverDebug then console.log 'COMMAND: ' + request.params.command + ' | Parameters: ' + debugDumpStr + ' | Host: ' + request.hostName

		parsedBody = parseBodyJSON(request.body.data)

		#Call onData, passing in the command from the path, parsed parameters from the body, and the response object
		onData(request.params.command, parsedBody, response)

	#A special path known only to the Kizzang backend
	app.use '/bcommand/:command', (request, response) ->

		#Debug out
		if serverDebug then console.log 'BACKDOOR COMMAND: ' + request.params.command + ' PARAMETERS: ' + JSON.stringify(request.body) + '| Host: ' + request.hostname

		#Make sure we are getting backdoor requests from the correct host
		if serverBackdoorHost != request.hostname and serverRequireHostCheck
			response.send (new ProtocolServer 0, 'server-invalid-hostname', { hostName: request.hostname }).out()
			return

		parsedBody = parseBodyJSON(request.body.data)

		onBackdoorData request.params.command, parsedBody, response

	#A special path that only the servers know, used for inter-server communications
	app.use "/scommand/:command", (request, response) ->

		#Debug out
		if serverDebug then console.warn 'INTER-SERVER COMMAND: ' + request.params.command + ' PARAMETERS: ' + request.body + '| Host: ' + request.hostname

		#Call onInterServerData
		onInterServerData request.params.command, parseBodyJSON(request.body.data), response


	#Synchronously connect to every available mySQL slot to ensure the system is working completely
	cycleNum = 0
	dynamicPoolNum = 0

	staticReadTest = ->

		staticReadPool.getConnection ($err, $conn) ->

			if $err

				console.warn "STATIC READ POOL CONNECTION ERROR: " 
				throw $err

			else

				if ++cycleNum < poolConnectionLimit

					staticReadTest()

				else

					console.log "Completed static read pool testing"
					cycleNum = 0
					staticWriteTest()

					#Release the connection when we are wrapping up
					$conn.release()

	staticWriteTest = ->

		staticWritePool.getConnection ($err, $conn) ->

			if $err

				console.warn "STATIC WRITE POOL CONNECTION ERROR"
				throw $err

			else

				if ++cycleNum < poolConnectionLimit

					staticWriteTest()

				else

					console.log "Completed static write pool testing"
					cycleNum = 0
					dynamicReadTest()

					#Release the connection when we are wrapping up
					$conn.release()

	dynamicReadTest = ->

		dynamicReadPools[dynamicPoolNum].getConnection ($err, $conn) ->

			if $err

				console.warn "DYNAMIC READ POOL CONNECTION ERROR"
				throw $err

			else

				if ++cycleNum < poolConnectionLimit

					dynamicReadTest()

				else

					console.log "Completed dynamic read pool testing for pool index: " + dynamicPoolNum
					cycleNum = 0
					dynamicWriteTest()

					#Release the connection when we are wrapping up
					$conn.release()


	dynamicWriteTest = ->

		dynamicWritePools[dynamicPoolNum].getConnection ($err, $conn) ->

			if $err

				console.warn "DYNAMIC WRITE POOL CONNECTION ERROR"
				throw $err

			else

				if ++cycleNum < poolConnectionLimit

					dynamicWriteTest()

				else

					console.log "Completed dynamic write pool testing for pool index: " + dynamicPoolNum
					cycleNum = 0

					dynamicPoolNum++
					if dynamicPoolNum < dynamicCount

						dynamicReadTest()

					#If we reach this point, allow the stack to unwrap, we are done testing!

					#Release the connection when we are wrapping up
					$conn.release()

	mySQLTest.checkMySQL(staticReadPool, dynamicReadPools[0], staticReadTest)

	# Get all the data from available tournaments at startup
	staticReadPool.query "SELECT * FROM SlotTournament", ($qerr, $backData) ->

		if $qerr

			console.warn badTableCheck($qerr) + "SlotTournament mySQL ERROR"
			throw $qerr

		else

			#Populate the tournamentData object
			for i in [0..($backData.length) - 1]

				populateTournaments $backData[i]

			#TESTING Spit back object
			console.log "Got tournament data"

	# Also get game data
	staticReadPool.query "SELECT * FROM SlotGame", ($qerr, $backData) ->

		if $qerr

			console.warn badTableCheck($qerr) + "SlotGame mySQL ERROR"
			throw $qerr

		else

			#Populate the gameData object
			for i in [0..($backData.length) - 1]

				populateGames $backData[i]

			console.log "Got game data"

	#Connect to memcached
	mcClient.connect ($err) ->

		if $err

			console.warn "MEMCACHED CONNECT ERROR"
			throw $err

		console.log "Connected to Memcached cluster"

		#Get the memcached versions we are running
		mcClient.version ($err, $version) ->

			if $err

				console.warn "MEMCACHED ACCESS ERROR"
				throw $err

			console.log "Running Memcached versions: " + $version

	#Verify the Redis connection
	redisClient.INFO "server", ($err, $res) ->

		if $err

			console.warn "REDIS ACCESS ERROR"
			throw $err

		else
			#Output the version of Redis we are using
			versionFind = new RegExp "redis_version.*"

			console.log "Connection to Redis server successful"
			ver = versionFind.exec($res)[0]

			console.log "Running Redis Version: " + ver.slice(ver.indexOf(":") + 1)



	#Listen at the port defined in the slotserver.xml
	server = app.listen serverPort, (request, response) ->

		#Verify that we are listening
		host = server.address().address
		port = server.address().port

		console.log '	 Slot Server listening at http://%s:%s', host, port


startPolicyServer = ->

	flashPolicyServer = net.createServer ($stream) ->

		$stream.setTimeout 0

		$stream.setEncoding "utf8"



		$stream.addListener "data", (data) ->

			if data.indexOf("<policy-file-request/>")!=-1

				console.log 'POLICY FILE SENT ON 10843'

				$stream.write "<cross-domain-policy><allow-access-from domain=\"*\" to-ports=\"*\" /><allow-http-request-headers-from domain=\"*\" headers=\"*\" /></cross-domain-policy>"

				$stream.end()



		$stream.addListener "end", -> $stream.end()


	#It is required that flash policy files are transferred over the port 843
	flashPolicyServer.listen 10843

	console.log "	 Flash policy server started on port 10843."


#==================================================================================================#

#HELPERS

#Verifies that xml data exists and adds it
importXMLData = (serverVar, xmlVar, varName, parseFunc) ->

	if xmlVar and xmlVar.length > 0

		#No problems!
		if parseFunc
			return parseFunc(xmlVar[0])
		else 
			return xmlVar[0]

	else

		#Problems! Don't print the default for security
		console.warn "WARNING: " + varName + " not found in slotserver.xml. Value reverting to default."

		return serverVar


#Parses the JSON in the request body, accounting for null fields
parseBodyJSON = (toParse) ->

	if not toParse

		return null

	else

		return JSON.parse toParse

#Extracts data from the FSTriggers, adding it to the passed object
extractFSTriggers = (fs, object) ->
	#The fsOn flag is the first byte in the hex string
	object.fsOn = fs.charAt(1) == "1" ? true : false

	#The fsSpinsLeft info is the 2nd and 3rd bytes
	object.fsSpinsLeft = parseInt(fs.slice(2, 6), 16)

	#The fsSpinsTotal info is the 4th and 5th bytes
	object.fsSpinsTotal = parseInt(fs.slice(6, 10), 16)

	#The fsMxTotal info is the 6th and 7th bytes
	object.fsMxTotal = parseInt(fs.slice(10, 14), 16)

	#The fsWinTotal info is the 8th and 11th bytes
	object.fsWinTotal = parseInt(fs.slice(14, 22), 16)

	#The fsWildSymbol is stored in the 12th and 13th bytes, we need to convert the hex into characters
	hexString = fs.slice(22)
	charString = ''

	for i in [0..1]
		subStr = hexString.substr(i*2, 2)

		if subStr != "00"
			charString += String.fromCharCode(parseInt(subStr, 16))

	if charString == '' then charString = null
	object.fsWildSymbol = charString


#Converts a wild symbol string with up to two characters into bits that can be stored into a buffer
getFSWildBits = (wild) ->

	#The bits will be stored in a buffer 2 bytes long
	bitBuf = new Buffer("0000", "hex")

	#if the wild symbol is null, return an empty buffer
	if not wild
		return bitBuf

	#Throw an error if our wild symbol has more than 2 characters
	if wild.length > 2 
		throw "ERROR: Wild Symbol can not have more than 2 characters! Wild: " + wild

	#Throw an error of our wild symbol has less than 1 character
	if wild.length <= 0
		throw "ERROR: Wild symbol has no characters!"

	#Add the data to be buffer
	bitBuf.write wild 

	return bitBuf


#Populates tournamentData with data
populateTournaments = (object) ->

	if not object
		return

	data =

		StartDate: new Date object.StartDate
		EndDate: new Date object.EndDate
		Prize: object.PrizeList

	tournamentData[object.ID.toString()] = data


#Populates gameData with data
populateGames = (object) ->

	if not object
		return

	data =

		Name: object.Name
		Theme: object.Theme
		Math: object.Math
		StartTime: new Date object.StartTime
		EndTime: new Date object.EndTime
		SpinsTotal: object.SpinsTotal
		SecsTotal: object.SecsTotal
		CreateDate: object.CreateDate

	gameData[object.ID.toString()] = data


#Extracts the session and player ID from redis data
extractRedisMember = (str) ->

	return str.split ":"


#Gets the input player's neighbors (The three top players, the player directly above, and the player directly below)
getNeighbors = (ourPlayerId, tournamentId, winTotal, callback) ->

	#Get all the rank data asynchronously
	finishedCount = 0

	topLeft = null #The number of top players remaining

	finished = false

	topPlayers = []

	nearPlayers = []

	finish = ->

		#Add the current player to the near players array, in between the high and low player
		nearPlayers.push nearPlayers[1]

		screenNameKey = "p" + ourPlayerId

		getMemcachedData screenNameKey, ($err, $res)->

			if $err or !$res

				msg = badTableCheck($err) + "getNeighbors-error-no-self-data"	

				console.warn msg + ": " + $err.toString()

				callback msg 
				finished = true

			else

				nearPlayers[1] = { PlayerID: ourPlayerId, WinTotal: winTotal, ScreenName: $res.ScreenName, FacebookID: $res.FacebookID }

				if ($res.FacebookID and $res.FacebookID != "")
					nearPlayers[1].FacebookID = $res.FacebookID
				
				if not nearPlayers[0]
					nearPlayers.shift()

				retObj = { top:topPlayers, near:nearPlayers }

				callback retObj
				finished = true

	#Get the top 3 players
	redisClient.ZREVRANGEBYSCORE tournamentId.toString(), "+inf", "-inf", "WITHSCORES", "LIMIT", 0, 10, ($err, $res) ->

		if $err or $res.length == 0

			if !finished
				callback "top-players-error"
				finished = true

		else
			#console.log "top player returns: " + $res.length
			topLeft = $res.length / 2

			#Loop through the top players, creating an object
			pushObject = null
			for i in [0..($res.length) - 1]

				if (i % 2) == 0

					#Create a new push object every even value
					pushObject = new Object

					#Even values are player IDs
					pushObject.PlayerID = extractRedisMember($res[i])[1]

					screenNameKey = "p" + pushObject.PlayerID.toString()

					getMemcachedData(screenNameKey, (($err, $res, $index)->

						if $err or !$res

							msg = badTableCheck($err) + "top-player-data-error"

							console.log msg + ": " + $err

							callback msg
							finish = true

						else
						
							pushIndex = $index / 2

							if topPlayers[pushIndex]

								topPlayers[pushIndex].ScreenName = $res.ScreenName

								if ($res.FacebookID and $res.FacebookID != "")
									topPlayers[pushIndex].FacebookID = $res.FacebookID

								if --topLeft == 0 and finishedCount == 3 and !finished

									finish()

							else

								topPlayers[pushIndex] = {ScreenName: $res}), i)

				else

					#Odd values are scores
					pushObject.WinTotal = $res[i]

					#Add the push object every odd value
					pushIndex = Math.floor(i / 2)

					if topPlayers[pushIndex]

						topPlayers[pushIndex].PlayerID = pushObject.PlayerID

						topPlayers[pushIndex].WinTotal = pushObject.WinTotal

						if --topLeft == 0 and finishedCount == 3 and !finished

							finish()

					else

						topPlayers[Math.floor(i / 2)] = pushObject

		if ++finishedCount == 3 and topLeft == 0 and !finished

			finish()


	#Get the player above us
	redisClient.ZRANGEBYSCORE tournamentId.toString(), winTotal + 1, "+inf", "WITHSCORES", "LIMIT", 0, 1, ($err, $res) ->

		if $err

			console.log "above-player-error: " + $err

			if !finished
					callback "above-player-error"
					finished = true

		else if $res.length == 0

			#We have the highest score!
			if ++finishedCount == 3 and topLeft == 0 and !finished

				finish()

		else
			
			#Create the object for the player above us, and put it into the first index of nearPlayers
			playerId = extractRedisMember($res[0])[1]

			winTotal2 = $res[1]
			screenName = null

			screenNameKey = "p" + playerId.toString()

			getMemcachedData screenNameKey, ($err, $res)->

				if $err or $res.length == 0

					msg = badTableCheck($err) + "above-player-error2"

					console.log msg + ": " + $err

					if !finished
						callback msg
						finished = true

				screenName = $res.ScreenName

				obj = 

					PlayerID: playerId

					WinTotal: winTotal2

					ScreenName: screenName

				if ($res.FacebookID and $res.FacebookID != "")
					obj.FacebookID = $res.FacebookID

				nearPlayers[0] = obj

				if ++finishedCount == 3 and topLeft == 0 and !finished

					finish()


	#Get the player below us
	redisClient.ZREVRANGEBYSCORE tournamentId.toString(), winTotal - 1, "-inf", "WITHSCORES", "LIMIT", 0, 1, ($err, $res) ->

		if $err

			console.log "below-player-error: " + $err

			if !finished
				callback "below-player-error"
				finished = true
		
		else if $res.length == 0

			#We have the lowest score :(
			if ++finishedCount == 3 and topLeft == 0 and !finished

				finish()

		else
			
			#Create the object for the player above us, and put it into the first index of nearPlayers
			playerId = extractRedisMember($res[0])[1]

			winTotal2 = $res[1]
			screenName = null

			screenNameKey = "p" + playerId.toString()

			getMemcachedData screenNameKey, ($err, $res)->

				if $err or $res.length == 0

					msg = badTableCheck($err) + "below-player-error2"

					console.log msg + ": " + $err

					if !finished
						callback msg
						finished = true

				else

					screenName2 = $res.ScreenName

					obj = 

						PlayerID: playerId

						WinTotal: winTotal2

						ScreenName: screenName2

					if ($res.FacebookID and $res.FacebookID != "")
						obj.FacebookID = $res.FacebookID

					nearPlayers[1] = obj

					if ++finishedCount == 3 and topLeft == 0 and !finished

						finish()


getMemcachedData = (key, callback, index) ->

	mcClient.get key, ($err, $res) ->

		if $err or !$res

			#The data was not found, we need to query the mySQL database

			#Get data out of the key
			if key.charAt(0) == "p" or key.charAt(0) == "f"

				ID = parseInt(key.slice(1))

			else

				ID = parseInt(key.slice(1, key.indexOf(":")))

			if key.charAt(0) == "l" #Identifies log data

				#Get the session ID from the key
				sessionId = parseInt(key.slice(key.indexOf(":") + 1))

				sql = "SELECT Gen, SpinsLeft, SpinsTotal, SecsLeft, SecsTotal, WinTotal, HEX(FSTriggers) AS FSTriggers FROM Log_? WHERE SessionID=? ORDER BY Gen DESC LIMIT 1"

				args = [ ID, parseInt(sessionId) ]

				dynamicReadPools[sessionId % dynamicCount].query sql, args, ($err, $backData) ->

					if $err

						callback $err, null

					else

						#We want to return null backdata because it identifies a player that has not spun yet
						if $backData[0]
							#We got data! Populate memcached with it and send it back
							argsBuffer = new Buffer(31)

							#Add the data that we got from mySQL to the buffer
							argsBuffer.writeUInt32BE(parseInt($backData[0].Gen), 0)
							argsBuffer.writeUInt16BE(parseInt($backData[0].SpinsLeft), 4)
							argsBuffer.writeUInt16BE(parseInt($backData[0].SpinsTotal), 6)
							argsBuffer.writeUInt16BE(parseInt($backData[0].SecsLeft), 8)
							argsBuffer.writeUInt16BE(parseInt($backData[0].SecsTotal), 10)
							argsBuffer.writeDoubleBE(parseInt($backData[0].WinTotal), 12)

							fsBuffer = new Buffer($backData[0].FSTriggers, "hex")
							fsBuffer.copy(argsBuffer, 20)

							if $backData[0].SecsLeft <= 0 then $backData[0].SecsLeft = 1 #Make sure we don't get negative exptime values

							#Add the buffer to memcached with the key that was searched for

							mcClient.set key, argsBuffer, { flags: memcachedFlags.LOG_DATA, exptime: $backData[0].SecsLeft + 10 }, ($err, $res) ->

								if $err

									console.log "Memcached set error 1: " + $err

								callback null, $backData[0]

						else

							callback null, $backData[0]

			else if key.charAt(0) == "s" #Identifies session data

				sql = "SELECT SessionID, PlayerID, GameID, StartTime FROM Session_? WHERE Token=?"

				#We use the entire key (because it is the token) except for the first identifying character
				args = [ ID, key.slice(1) ]

				staticReadPool.query sql, args, ($err, $backData) ->

					if $err or not $backData[0]

						callback $err, null

					else

						#Add the data to a buffer
						argsBuffer = new Buffer(28)

						argsBuffer.writeDoubleBE(parseInt($backData[0].SessionID), 0)
						argsBuffer.writeDoubleBE(parseInt($backData[0].PlayerID), 8)
						argsBuffer.writeUInt32BE(parseInt($backData[0].GameID), 16)
						argsBuffer.writeDoubleBE(parseInt($backData[0].StartTime), 20)

						#We need to calculate the seconds remaining in order to establish the expiration time
						secsTotal = null

						if gameData[$backData[0].GameID.toString()]

							secsTotal = gameData[$backData[0].GameID.toString()].SecsTotal

							secsLeft = secsTotal - (common.secondsBetween (new Date(parseInt $backData[0].StartTime)), new Date())

							if secsLeft <= 0 then secsLeft = 1 #Make sure we don't get negative exptime values

							#Add the buffer to memcached

							mcClient.set key, argsBuffer, { flags: memcachedFlags.SESSION_DATA, exptime: secsLeft + 10 }, ($err, $res) ->

								if $err

									console.log "Memcached set error 2: " + $err

								callback null, $backData[0]

						else

							#No data was found, try mySQL
							sql = "SELECT * FROM SlotGame WHERE ID=?"

							args = [parseInt $backData[0].GameID]

							staticReadPool.query sql, args, ($err, $backData) ->

								if $err or not $backData[0]

									callback $err, null

								else

									#Take this opportunity to populate the games data as well
									populateGames $backData[0]

									secsTotal = $backData[0].SecsTotal

									secsLeft = secsTotal - (common.secondsBetween (new Date(parseInt $backData[0].StartTime)), new Date())

									if secsLeft <= 0 then secsLeft = 1 #Make sure we don't get negative exptime values

									#Add the buffer to memcached

									mcClient.set key, argsBuffer, { flags: memcachedFlags.SESSION_DATA, exptime: secsLeft + 10 }, ($err, $res) ->

										if $err

											console.log "Memcached set error 3: " + $err

										callback null, $backData[0]

			else if key.charAt(0) == "p" #Identifies player screen name data

				sql = "SELECT ScreenName, FacebookID FROM Players WHERE PlayerID=?"

				args = [ ID ]

				staticReadPool.query sql, args, ($err, $backData) ->

					data = $backData[0]

					if $err

						callback $err, null

					else if not $backData[0]

						callback "no-data", null

					else

						mcClient.set key, data.ScreenName, { flags: memcachedFlags.SCREEN_NAME, exptime: screenNameExp }, ($err, $res) ->

							if $err

								console.log "Memcached set error 4: " + $err
							
							if data.FacebookID

								mcClient.set ("f" + key.slice(1)), data.FacebookID, { flags: memcachedFlags.FACEBOOK_ID, exptime: screenNameExp }, ($err, $res) ->
									
									if $err

										console.log "Memcached set error 5: " + $err

							callback null, $backData[0], index

			else
				#invalid key!
				callback "Invalid Key! Key identifier: " + key.charAt(0), null

		else

			if key.charAt(0) == "p"

				backData = { ScreenName: $res[key] }

				# If we are getting player data then we need to also get facebook data

				mcClient.get ("f" + key.slice(1)), ($err, $res) ->

					if $err or !$res

						sql = "SELECT FacebookID FROM Players WHERE PlayerID=?"

						args = [ ID ]

						staticReadPool.query sql, args, ($err, $backData) ->

							if $err

								callback $err, null

							else if not $backData[0]

								callback null, backData, index

							else
								
								if $backData[0].FacebookID

									mcClient.set ("f" + key.slice(1)), $backData[0].FacebookID, { flags: memcachedFlags.SCREEN_NAME, exptime: screenNameExp }, ($err, $res) ->

										if $err

											console.log "Memcached set error 6: " + $err.toString()

										backData.FacebookID = $backData[0].FacebookID

								callback null, backData, index

					else

						backData.FacebookID = $res[("f" + key.slice(1))]

						callback null, backData, index

			else

				callback null, $res[key], index

apiHTTPRequest = (path, appToken, apiKey, callback, bodyData, encode = false) ->

	didError = false

	#Create the url to query
	hostUrl = serverBackdoorHost

	#The server connection options
	options =
		host: hostUrl
		path: path
		method: "POST"
		headers: { 'content-type': 'application/x-www-form-urlencoded', "X-API-KEY": apiKey, "TOKEN": appToken }

	#Send the request via HTTPS
	req = http.request options, (response) ->

		dataHold = ""

		response.on 'data', (data) ->
			dataHold += data

		response.on 'end', ->
			
			if serverDebug
				console.log "DATA FROM " + hostUrl + " "  + path + ": " + dataHold

			if callback and not didError

				callback { status: response.statusCode, data: dataHold }

	req.on 'error', (error) ->
		console.error "ERROR FROM " + path + ": RegToken api request failure: " + error.message

		if not didError
			callback()

		didError = true

	#URL Encode the data if we need to
	if encode
		bodyData = urlencoder.encode(JSON.parse(bodyData))

	req.write bodyData

	req.setTimeout serverAPITimeout, ()->

		console.warn "WARNING: API Server Timeout after " + serverAPITimeout + "ms"

		if not didError 
			callback { status: API_TIMEOUT }

		didError = true

	req.end()

isEmpty = (str) ->

	if str && str.length != 0

		return false

	else

		return true

#==================================================================================================#

#STARTUP



#Main

#Handle malformed or missing versions
if (!pjson or !pjson.version)
	versionNumber = " VERSION ERROR"
else
	versionNumber = pjson.version

console.log "\n\nKizzang Slot Server v" + versionNumber

getConfiguration -> #Config file

	getMySqlTime -> #Get mySQL time

		startSlotServer()

		startPolicyServer()





#==================================================================================================#
