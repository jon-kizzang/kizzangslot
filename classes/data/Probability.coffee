#Created by Tony Suriyathep on 2013.12.30

common = require("../../include/common")


#==================================================================================================#
#One item of a probability


class exports.ProbabilityItem


	accumulator: 0
	weight: 0
	value: 0


	constructor: (@accumulator,@weight,@value)->


#==================================================================================================#
#Run a probability


class exports.Probability


	id: null #name it
	total: 0
	items: null


	constructor: (@id)->
		@total = 1
		@items = []


	add: (weight,value)->
		@items.push new exports.ProbabilityItem(@total,weight,value)
		@total += weight


	run: ->
		rnd = common.randomInteger(1,@total)
		for i in [(@items.length-1)..0] #Go backwards
			item = @items[i]
			if rnd >= item.accumulator then return item.value
		return null #failed??


	#Import single line
	@importFromXml: (json)->
		probability = new Probability(json.$.id)
		for range in json.range
			probability.add parseInt(range.$.weight), range.$.value
		return probability