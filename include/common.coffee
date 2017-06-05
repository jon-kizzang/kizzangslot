#=================================================================================================#
#FILE


#Get file extension with no DOT
@getFileExtension = ($filename)->
  i = $filename.lastIndexOf '.'
  if i < 0 then return ''
  return $filename.substr i+1

#Get file name only, remove extension
@getFileName = ($filename)->
  i = $filename.lastIndexOf '.'
  if i < 0 then return ''
  return $filename.substr 0,i


#=================================================================================================#
#DATE
#http://stackoverflow.com/questions/4435605/javascript-date-difference


#Create a new date with days added
@addDays = ($days,$date = new Date())-> new Date $date.getTime() + ($days*24*60*60*1000)  


#Create a new date with hours added
@addHours = ($hours,$date = new Date())-> new Date $date.getTime() + ($hours*60*60*1000)  


#Create a new date with minutes added
@addMinutes = ($minutes,$date = new Date())-> new Date $date.getTime() + ($minutes*60*1000)  


#Create a new date with seconds added
@addSeconds = ($seconds,$date = new Date())-> new Date $date.getTime() + ($seconds*1000)  


#Count number of days between two dates
@daysBetween = ($date1, $date2 = new Date())-> Math.round (Math.abs($date1.getTime() - $date2.getTime())) / (1000 * 60 * 60 * 24)


#Count number of minutes between two dates
@hoursBetween = ($date1, $date2 = new Date())-> Math.round (Math.abs($date1.getTime() - $date2.getTime())) / (1000 * 60 * 60)


#Count number of minutes between two dates
@minutesBetween = ($date1, $date2 = new Date())-> Math.round (Math.abs($date1.getTime() - $date2.getTime())) / (1000 * 60)


#Count number of seconds between two dates
@secondsBetween = ($date1, $date2 = new Date())-> Math.round (Math.abs($date1.getTime() - $date2.getTime())) / 1000


#==================================================================================================#
#STRING


@ucfirst = (s)-> 
  if not s then return ''
  return s.substr(0,1).toUpperCase()+s.substr(1).toLowerCase()

#Check if there is a string match at a specific location
@matchAt = (s, frag, i) -> return s[i...i+frag.length] == frag

#Check if string starts with another string 
@startsWith = (s, frag) -> return @matchAt s, frag, 0

#Check if a string endswith another string 
@endsWith = (s, frag) -> return @matchAt s, frag, s.length - frag.length


#==================================================================================================#
#ARRAY


#Shuffle randomize array
@shuffle = (a) ->
	i = a.length
	while --i > 0
		j = ~~(Math.random() * (i + 1)) # ~~ is a common optimization for Math.floor
		t = a[j]
		a[j] = a[i]
		a[i] = t
	return a


#Remove elements from array
#http://stackoverflow.com/questions/8205710/remove-a-value-from-an-array-in-coffeescript
@splice = ($array,$find) ->
	i = $array.indexOf $find
	return $array.splice i,1


#==================================================================================================#



#==================================================================================================#
#STRING


@matchAt = (s, frag, i) -> s[i...i+frag.length] == frag


@startsWith = (s, frag) -> @matchAt s, frag, 0


@endsWith = (s, frag) -> @matchAt s, frag, s.length - frag.length


@toBoolean = (s)->
	if not s then return false
	s = s.toLowerCase()
	if s.substr(0,1)=="t" or s.substr(0,1)=="y" or s.substr(0,2)=="on" or s=="1" then return true
	return false
	
@toRank = (n)->
	if not n then return ''
	else if n>=10 and n<=20 then return n+'th'
	
	ending = ''
	str = ''+n
	lastDigit = str.substr(str.length-1,1)
	if lastDigit == '1' then ending = 'st'
	else if lastDigit == '2' then ending = 'nd'
	else if lastDigit == "3" then ending = 'rd'
	else ending = 'th'
	
	return str+ending	
#==================================================================================================#



#==================================================================================================#
#NUMBERS


#Returns an integer
@randomInteger = (min,max)->
	if min==max then return min
	return min+Math.floor(Math.random()*(1+max-min))


#Returns a decimal
@randomDecimal = (min,max)->
	if min==max then return min
	return min+(Math.random()*(1+max-min))


#Returns 0 or 1
@randomBoolean = ()-> return Math.floor(Math.random()*2)==1


#Take a number and make sure it doesn't pass maxNum
@rotateNumber = (index,maxNum)->
	maxNum++;
	if index>=maxNum then index=index%maxNum #Handle positive
	else if index<0 then index=(index%maxNum)+maxNum #Handle negative
	return if index==maxNum then 0 else index

	
#http://kun.io/blog/42051818404/Node.js:-Creating-a-Random-String
@randomCode = ($len) ->
	cd = ''
	letters = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz0123456789' #Remove letters O, L, I
	for i in [1..$len]
		cd += letters[@randomInteger(0,letters.length-1)]
	return cd
#==================================================================================================#


#==================================================================================================#
#GENERAL


#http://coffeescriptcookbook.com/chapters/classes_and_objects/cloning
@clone = (obj) ->
	if not obj? or typeof obj isnt 'object'
		return obj

	if obj instanceof Date
		return new Date(obj.getTime()) 

	if obj instanceof RegExp
		flags = ''
		flags += 'g' if obj.global?
		flags += 'i' if obj.ignoreCase?
		flags += 'm' if obj.multiline?
		flags += 'y' if obj.sticky?
		return new RegExp(obj.source, flags) 

	newInstance = new obj.constructor()

	for key of obj
		newInstance[key] = @clone obj[key]

	return newInstance
	
	
#==================================================================================================#
#MYSQL


@toMySqlDateTime = (date) ->
  return @toMySqlDate(date)+' '+@toMySqlTime(date)


@toMySqlTime = (date) ->
  timeStamp = [date.getHours(), date.getMinutes(), date.getSeconds()].join(":")
  timeStamp = timeStamp.replace /\b(\d)\b/g, "0$1"
  return timeStamp.replace /\s/g, ""
  
 
@toMySqlDate = (date) ->
  timeStamp = [date.getFullYear(), (date.getMonth() + 1), date.getDate()].join("-")
  timeStamp = timeStamp.replace( /\b(\d)\b/g, "0$1" )
  return timeStamp.replace /\s/g, ""
#==================================================================================================#



