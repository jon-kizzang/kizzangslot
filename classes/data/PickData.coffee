#Created by Tony Suriyathep on 2013.12.30

#==================================================================================================#
#Run a probability

class exports.PickData

	prize: 0
	spins: 0
	mx: 1
	outcome: null

	constructor: (@prize=0,@spins=0,@mx=1,@outcome=null)->

	toJSON: -> 
		obj = {}
		if @prize>0 then obj.prize = @prize
		if @spins>0 then obj.spins = @spins
		if @mx>1 then obj.mx = @mx
		if @outcome!=null then obj.outcome = @outcome
		return obj	