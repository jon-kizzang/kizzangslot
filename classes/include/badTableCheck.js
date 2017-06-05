/**
 * This function will parse a SQL error to try and determine what kind of error
 * was caused.
 * 
 * It will return an easily read identifier
 */
module.exports = function(err) {
	if (!err) return "";
	
	if (err.toString().indexOf("Unknown column") != -1) {
		
		// A Column is missing!
		return "colimnMissing";
	}
	
	if (err.toString().indexOf("doesn't exist") != -1) {
		
		// A table is missing
		return "tableMissing";
	}
	
	return "";
}
