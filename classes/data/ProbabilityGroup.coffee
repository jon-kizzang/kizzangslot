#Created by Tony Suriyathep on 2013.12.30

Probability = require("./Probability").Probability


#==================================================================================================#
#Group of probabilities


class exports.ProbabilityGroup


	id: null
	probabilities: null


	constructor: (@id)-> @probabilities=[]
	add: (probability)-> @probabilities.push probability
	run: (id)-> return (@probabilities.filter (obj)->obj.id==id)[0].run()


	#Import single 
	@importFromXml: (json)->
		probabilityGroup = new ProbabilityGroup(json.$.id)

		#Import lines
		for probability in json.probability
			probabilityGroup.probabilities.push Probability.importFromXml probability

		return probabilityGroup