#Created by Tony Suriyathep on 2013.12.30

Line = require("./Line").Line


#==================================================================================================#
#Group of lines


class exports.LineGroup

	id: null #Name of group of lines
	reels: 0
	rows: 0
	lines: null


	constructor: (@id,@lines)->
	getLine: (lineId)-> return @lines[lineId-1]


	#Import single lineGroup
	@importFromXml: (json)->
		lineGroup = new LineGroup()
		lineGroup.id = json.$.id
		lineGroup.reels = parseInt json.$.reels
		lineGroup.rows = parseInt json.$.rows

		#Import lines
		lineGroup.lines = []
		for line in json.line
			lineGroup.lines.push Line.importFromXml line

		#Sort lines
		lineGroup.lines.sort (a, b) -> a.id - b.id

		return lineGroup

