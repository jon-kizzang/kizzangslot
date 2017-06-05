fs = require 'fs'
mysql = require 'mysql2'
xml2js = require 'xml2js'
nodemailer = require 'nodemailer'
common = require '../include/common'

dbPool = null
curDate = null
emailFrom = "Tony Suriyathep <tony.suriyathep@kizzang.com>" 
emailTo = "tony.suriyathep@kizzang.com" 
emailSubjectPrefix = "Kizzang Slot Server:"
emailMessage = ""
emailMailer = null


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
getCurrentDate = (addHours=-8) ->
	d = new Date()
	if isDaylightSavingsOn(d) then addHours++ 
	return new Date(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), d.getUTCHours()+addHours, d.getUTCMinutes(), d.getUTCSeconds())

#==================================================================================================#

sendEmail = ($subject,$onComplete) ->
	mailOptions =
	  from: emailFrom 
	  to: emailTo 
	  subject: emailSubjectPrefix+' '+$subject 
	  text: emailMessage
	emailMailer.sendMail mailOptions, ($err, $res) ->
		if $err then console.log $err
		if $onComplete then $onComplete()
	    
	    
getConfiguration = ->
	emailMessage += "Server Time = "+curDate+"\n"
	emailMessage += "Reading configuration file.\n"
	xmlData = fs.readFileSync __dirname + '/../slotserver.xml'
	
	parser = new xml2js.Parser {trim:true}
	parser.parseString xmlData, ($err, $result) ->
		if $err 
			emailMessage += "Could not read XML file.\n"
			endCron "ERROR"
			return

		config = $result.configuration

		#Setup mySQL pool
		dbPool = mysql.createPool(
			host: config.mySQL[0].host[0]
			port: parseInt config.mySQL[0].port[0]
			user: config.mySQL[0].user[0]
			password: config.mySQL[0].password[0]
			database: config.mySQL[0].database[0]
			debug: common.toBoolean config.mySQL[0].debug[0]
		)
		
		#Setup emailer
		emailFrom = config.email[0].senderName[0]+' <'+config.email[0].senderEmail[0]+'>'
		emailSubjectPrefix = config.email[0].subjectPrefix[0]
		mailerOptions = 			
			service: "Gmail"
			auth: 
				user: config.email[0].user[0]
				pass: config.email[0].password[0]
		emailMailer = nodemailer.createTransport "SMTP", mailerOptions

		getConnection()

		
getConnection = ->	
	emailMessage += "Connecting to mySQL.\n"

	#Get a server ID from mySQL
	dbPool.getConnection ($err,$db) ->
		if $err 
			emailMessage += "Could not connect to mySQL.\n"
			endCron "ERROR"
			return
		console.log "Connected to mySQL."

		checkTournamentsAdded = ->
			sql = "SELECT * FROM SlotTournament WHERE Date = ? LIMIT 1"
			args = [common.toMySqlDate(curDate)]
			$db.query sql, args, ($err,$rows)->
				if $err 
					emailMessage += $err
					endCron "ERROR"
					return
				else if $rows and $rows.length>0 
					emailMessage += "This day was already run, aborting cron!\n"
					endCron "DUPE"
					return
				insertTournaments()
				
		#Insert all SlotGame into SlotTournament
		insertTournaments = ->
			sql = "SELECT g.ID as GameID,t.ID as TimeID,t.StartTime,t.EndTime,g.Name,g.Theme,g.Math,t.SpinsTotal,t.SecsTotal FROM SlotGame g,SlotTime t ORDER BY g.ID,t.ID"
			$db.query sql, ($err,$rows)->
				if $err
					emailMessage += $err
					endCron "ERROR"
					return
				
				sql = "INSERT INTO SlotTournament SET Date=?, GameID=?, TimeID=?, StartDate=?, EndDate=?"
				
				c = 0
				for row in $rows
					console.log "Inserting for GameID = "+row.GameID+", TimeID = "+row.TimeID
					
					startHours = parseInt(row.StartTime.toString().substr(0,2))
					startMinutes = parseInt(row.StartTime.toString().substr(3,2))
					endHours = parseInt(row.EndTime.toString().substr(0,2))
					endMinutes = parseInt(row.EndTime.toString().substr(3,2))
					
					args = []							
					args.push new Date(curDate.getFullYear(), curDate.getMonth(), curDate.getDate(), 0, 0, 0)		
					args.push row.GameID	
					args.push row.TimeID	
					args.push new Date(curDate.getFullYear(), curDate.getMonth(), curDate.getDate(), startHours, startMinutes, 0)
					args.push new Date(curDate.getFullYear(), curDate.getMonth(), curDate.getDate(), endHours, endMinutes, 0)
					
					$db.query sql, args, ($err,$result)->
						if $err 
							emailMessage += $err
							endCron "ERROR"
							return
						c++
						if c==$rows.length then endCron 'OK'
						
		checkTournamentsAdded()


endCron = ($subject) ->
	emailMessage += "Cron ended.\n"
	console.log emailMessage
	sendEmail "CRON "+$subject, ()->	
		process.exit()
		
		
#==================================================================================================#

					
console.log "Cron started."
curDate = getCurrentDate()
getConfiguration()



