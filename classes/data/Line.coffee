#Created by Tony Suriyathep on 2013.12.30

#==================================================================================================#
#Data for 1 line


class exports.Line


	id: 0
	rows: null #1 based array of rows


	constructor: (@id,@rows)-> return


	#Import single line
	@importFromXml: (json)->
		line = new Line()
		line.id = parseInt json.$.id
		line.rows = json.$.rows.split(',').map (val)-> return parseInt val
		return line