#Created by Tony Suriyathep on 2013.12.30

#==================================================================================================#
#Player data

class exports.Player

	id:null
	type:"Fun" #Fun,RTP,Cash, if RTP then insufficient funds ignored
	hasAccount:false #Linked to account?
	balance:0
	games:{} #An array of slotGamePlayer

	constructor: (@id)->