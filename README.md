KizzangSlotServer
=================

Node.js server for Kizzang slot games. This server is responsible for communicating with mysql to track active slot games.

Accessing the Server
===========================================
###*NOTE: This section represents an API that is still in development and is not neccesarilly a true API contract.*

The server is accessed through the use of various commands; each command has a seperate enpoint, and most commands require parameters in the form of stringified JSON in the request body. All commands must be in the form of POST requests and the `content-type` header must be set to `application/x-www-form-urlencoded`

The responses will always be returned as a JSON object with 4 fields: 
```JSON
{ "ok": "a", 
  "msg": "b", 
  "request": "c", 
  "response": "d" }
```
The `"ok"` field describes if the command was successful or not. a value of 1 represents success, and a value of 0 represents failure.

The `"msg"` field includes a message that will give information on what command was just completed, or why a command may have failed.

The `"request"` field simply echos the command and any included parameters from the request in the following format:
```JSON
{ "command": "a",
  "params": "b" }
```

Finally, the `"response"` field contains all of the information generated by the server for the client after a command is successfully called. This information is different for every command. The request and response format for each command is detailed below.
###User Accessable Commands
These commands can be accessed by simply going to the correct endpoint with the correct parameters in the request body.

####Assets `<host>/command/assets`

| Request | Response |
|---------|----------|
| `{ gameId: a }` | `{ math: b, theme: c }` |

The `assets` command retrieves math and theme xml data for the requested game

######Example Request (curl)
```terminal
curl --data-urlencode "data={\"gameId\":1}" http://0.0.0.0:1337/command/assets -H "content-type:application/x-www-form-urlencoded"
```

######Example Response
```JSON
{"ok":1,"msg":"assets-ok","request":{"command":"assets","params":{"gameId":1}},"response":{"math":{"$":{"id":"butterflytreasures"},"typeMethod":["Lines"],"typeDirection":["Normal"],"typeCascading":["N"],"reels":["5"],"rows":["3"],"denomList":["1,2,5,10,25,50,100,1000"],"denomDefault":["100"],"coinList":["1,2,5,10,25,50,100,1000"],"coinDefault":["1"],"fsSpinsTotal":["10"],"fsSecsAdded":["60"],"fsMxTotal":["1"],"pickSymbols":["P1,P2,P3"],"stripGroup":[{"$":{"id":"base","reels":"5","rows":"3"},"strip":[{"$":{"symbols":"P4,P5,P7,W,S,P1,B,W,P6,S,P2,P5,B,S,P3,W,P7,P6"}},{"$":{"symbols":"P1,P6,S,P7,W,P5,P2,P7,W,P5,P7,S,W,P6,P1,P4,P5,W,P4,P2,S,W,P3,P1,P6,W,P3,S,P4,P2,P3,S"}},{"$":{"symbols":"P5,W,P6,P1,B,P2,P4,S,W,B,P7,W,P3,S,P5,P6,P7,S"}},{"$":{"symbols":"P1,P7,W,P5,P1,P2,P4,W,P3,P7,P6,W,P5,P1,P7,S,P6,P3,S,P2,P5,W,S,P6,P4,W,P2,S,P3,W,S,P4"}},{"$":{"symbols":"P5,P7,B,P6,P3,B,P1,S,P4,P2,S,W,B,S,P5,P6,P7"}}]},{"$":{"id":"bonusP1","reels":"5","rows":"3"},"strip":[{"$":{"symbols":"P4,P5,P7,P6,P3,P1,P2,P7,P6,P1,P2,P5,B,S,P6,B,P2,P5,P6,P4,P3,P7"}},{"$":{"symbols":"P1W,P6,P2,P7,W,P5,P2,P7,P3,P5,P7,S,P5,P6,P1W,P4,P5,P3,P4,P2,S"}},{"$":{"symbols":"P5,B,P6,P1W,P7,P2,B,P1W,P6,S,P7,P2,P5,P4,W,P3,P5,P4,P7,P3,S"}},{"$":{"symbols":"P1W,P7,P4,P5,P1W,P2,P4,P5,P3,P7,P6,W,P5,P1W,P7,S,P6,P3,P7,P6,P5"}},{"$":{"symbols":"P5,P7,P2,P6,P3,P5,P1W,B,P5,P4,B,P6,P2,W,P7,P1W,P2,P5,S,P3,P7,P6,P4,P7,P3"}}]},{"$":{"id":"bonusP2","reels":"5","rows":"3"},"strip":[{"$":{"symbols":"P4,P5,P7,P6,P3,P1,P2,P7,P6,P1,P2,P5,B,S,P6,B,P2,P5,P6,P4,P3,P7"}},{"$":{"symbols":"P1,P6,P2W,P7,W,P5,P2W,P7,P3,P5,P7,S,P5,P6,P1,P4,P5,P3,P4,P2W,S"}},{"$":{"symbols":"P5,B,P6,P1,P7,P2W,B,P1,P6,S,P7,P2W,P5,P4,W,P3,P5,P4,P7,P3,S"}},{"$":{"symbols":"P1,P7,P4,P5,P1,P2W,P4,P5,P3,P7,P6,W,P5,P1,P7,S,P6,P3,P7,P6,P5"}},{"$":{"symbols":"P5,P7,P2W,P6,P3,P5,P1,B,P5,P4,B,P6,P2W,W,P7,P1,P2W,P5,S,P3,P7,P6,P4,P7,P3"}}]},{"$":{"id":"bonusP3","reels":"5","rows":"3"},"strip":[{"$":{"symbols":"P4,P5,P7,P6,P3,P1,P2,P7,P6,P1,P2,P5,B,S,P6,B,P2,P5,P6,P4,P3,P7"}},{"$":{"symbols":"P1,P6,P2,P7,W,P5,P2,P7,P3W,P5,P7,S,P5,P6,P1,P4,P5,P3W,P4,P2,S"}},{"$":{"symbols":"P5,B,P6,P1,P7,P2,B,P1,P6,S,P7,P2,P5,P4,W,P3W,P5,P4,P7,P3W,S"}},{"$":{"symbols":"P1,P7,P4,P5,P1,P2,P4,P5,P3W,P7,P6,W,P5,P1,P7,S,P6,P3W,P7,P6,P5"}},{"$":{"symbols":"P5,P7,P2,P6,P3W,P5,P1,B,P5,P4,B,P6,P2,W,P7,P1,P2,P5,S,P3W,P7,P6,P4,P7,P3W"}}]}],"symbolGroup":[{"$":{"id":"base"},"symbol":[{"$":{"id":"P7","wild":"N","scatter":"N","mx":"1","pays":"0,0,10,25,50"}},{"$":{"id":"P6","wild":"N","scatter":"N","mx":"1","pays":"0,0,15,50,100"}},{"$":{"id":"P5","wild":"N","scatter":"N","mx":"1","pays":"0,0,15,75,150"}},{"$":{"id":"P4","wild":"N","scatter":"N","mx":"1","pays":"0,0,20,100,250"}},{"$":{"id":"P3","wild":"N","scatter":"N","mx":"1","pays":"0,0,20,150,500"}},{"$":{"id":"P2","wild":"N","scatter":"N","mx":"1","pays":"0,0,25,200,750"}},{"$":{"id":"P1","wild":"N","scatter":"N","mx":"1","pays":"0,0,50,250,1000"}},{"$":{"id":"W","wild":"Y","scatter":"N","mx":"1","pays":"0,0,50,250,1000"}},{"$":{"id":"P1W","wild":"Y","scatter":"N","mx":"1","pays":"0,0,50,250,1000"}},{"$":{"id":"P2W","wild":"Y","scatter":"N","mx":"1","pays":"0,0,50,250,1000"}},{"$":{"id":"P3W","wild":"Y","scatter":"N","mx":"1","pays":"0,0,50,250,1000"}},{"$":{"id":"S","wild":"N","scatter":"Y","mx":"1","pays":"0,0,5,10,25"}},{"$":{"id":"B","wild":"N","scatter":"Y","mx":"1","pays":"0,0,5,0,0"}}]}],"lineGroup":[{"$":{"id":"base","reels":"5","rows":"3"},"line":[{"$":{"id":"1","rows":"2,2,2,2,2"}},{"$":{"id":"2","rows":"1,1,1,1,1"}},{"$":{"id":"3","rows":"3,3,3,3,3"}},{"$":{"id":"4","rows":"1,2,3,2,1"}},{"$":{"id":"5","rows":"3,2,1,2,3"}},{"$":{"id":"6","rows":"1,1,2,3,3"}},{"$":{"id":"7","rows":"3,3,2,1,1"}},{"$":{"id":"8","rows":"2,1,2,3,2"}},{"$":{"id":"9","rows":"2,3,2,1,2"}},{"$":{"id":"10","rows":"1,2,2,2,3"}},{"$":{"id":"11","rows":"3,2,2,2,1"}},{"$":{"id":"12","rows":"2,1,1,1,2"}},{"$":{"id":"13","rows":"2,3,3,3,2"}},{"$":{"id":"14","rows":"2,1,1,2,3"}},{"$":{"id":"15","rows":"2,3,3,2,1"}},{"$":{"id":"16","rows":"3,2,1,1,2"}},{"$":{"id":"17","rows":"1,2,3,3,2"}},{"$":{"id":"18","rows":"1,2,1,2,1"}},{"$":{"id":"19","rows":"3,2,3,2,3"}},{"$":{"id":"20","rows":"2,1,2,1,2"}},{"$":{"id":"21","rows":"2,3,2,3,2"}},{"$":{"id":"22","rows":"3,2,1,1,1"}},{"$":{"id":"23","rows":"1,2,3,3,3"}},{"$":{"id":"24","rows":"1,1,1,2,3"}},{"$":{"id":"25","rows":"3,3,3,2,1"}}]}]},"theme":{"$":{"id":"butterflytreasures"},"name":["Butterfly Treasures"],"assets":[{"asset":[{"id":["slot"],"file":["butterflytreasures.0.zip"]}]}],"screen":["GameButterflyTreasures"],"logoAdjustX":["0"],"logoAdjustY":["-40"],"meterTextSize":["20"],"meterSpinAdjustX":["0"],"meterSpinAdjustY":["0"],"meterTimeAdjustX":["0"],"meterTimeAdjustY":["0"],"meterWinAdjustX":["0"],"meterWinAdjustY":["0"],"meterTotalAdjustX":["0"],"meterTotalAdjustY":["0"],"meterBonusFont":["font_bonus"],"meterBonusFontSize":["52"],"meterBonusSuffix":["FREE SPINS"],"meterBonusAdjustX":["-14"],"meterBonusAdjustY":["-50"],"meterPopupFont":["font_popup"],"meterPopupTextSize":["30"],"meterPopupAdjustX":["10"],"meterPopupAdjustY":["90"],"reels":[{"symbolWidth":["144"],"symbolHeight":["144"],"rampPercent":["0.25"],"rampSeconds":["0.25"],"speedRowsPercent":["3"]}],"highlights":[{"highlightDelay":["2.1"],"highlightTween":["0.25"],"rollupMaxSeconds":["3"]}]}}}
```

####Join `<host>/command/join` DEPRECIATED

| Request | Resonse |
|---------|---------|
| N/A | N/A |

The `join` command has been depreciated. Tournaments and sessions are now both joined with the `regToken` command.


####Spin `<host>/command/spin`

| Request | Response |
|---------|----------|
| `{ playerToken: a, appToken: b, apiKey: c }` | `{ state: d, spin: e, neighbors: f[, eventId: g] }` |

The `spin` command causes a spin to be made. The data from that spin is then saved and sent back to the client. The unique player token that was given to the player on registration must be given in order to spin. The `state` field can contain the following fields:
```JSON
{ "spinsLeft": "a",
  "spinsTotal": "b",
  "secsLeft": "c",
  "secsTotal": "d",
  "winTotal": "e",
  "fsOn": "f",
  "fsTrigger": "g",
  "fsSpinsLeft": "h",
  "fsSpinsTotal": "i",
  "fsMxTotal": "j",
  "fsWinTotal": "k",
  "fsWildSymbol": "l"
  "bonusPick": "m" }
```
Note that if the game does not have a free spin state, then the only "fs" field returned will be `fsTrigger` as null, and if the current game does not have bonus picks then the `bonusPick` field will not be returned.

Information on the top three players', as well as information on the player immediately above and below the spinning player, as well as information on the player themselves in score is also provided, formatted as follows. Note that player information is always in descending order based on score. If there are fewer than three players or the spinning player holds the top / bottom position (And thus, there are no players above / below the spinning player) then the empty slots will be removed from the array.
```JSON
{ "top": [ "a" ,"b" ,"c" ],
  "near": [ "e", "f", "g" ] }
```
*NOTE: The Spin command can only be successfully called after this command has been called and before the time limit for the selected game has run out*

When a player makes their last spin for a game and they are not in one of the top three positions, a post will be made to the Kizzang API, and the server will expect a response body of with a field named `id` that contains an event id for the client. The specific API is dependent on the current environment defined in [slotserver.xml](slotserver.xml). This post shall contain the following url encoded body information:
```JSON
{"type":"slotTournament","serialNumber":"KSxxxxx","entry":"a"}
```
The `type` field will always be "slotTournament". The `serialNumber` is the 5 digit numerical ID of the slot tournament defined in mySQL, and the `entry` field is the currently spinning player's current session ID.

The request will also contain wo custom headers, `TOKEN` and `X-API-KEY`. The `TOKEN` header will contain the appToken provided in the initial request, and the `X-API-KEY` will contain a the apiKey provided in the initial request. This request will timeout after a certain number of milliseconds defined in [slotserver.xml](slotserver.xml) (defaulting to 5000), if the request times out then the message `-API-timeout` will be *appended* to the response message. If the API request does not return a 2xx response, the message `-API-failure` will be appended to the response message, if the data can not be then the message `-API-bad-data` will be appended, and finally, if the event id data is missing the message `-API-no-id` will be appended. The eventId field is only populated when an API call is successfully made, so it should always be checked for null. **A bad response from the API request does NOT stop the spin operation** If the spinning player is in one of the top three positions on their last spin the message will be appended with `-in-top-three`

######Example Request (curl)
```terminal
curl --data-urlencode "data={\"playerToken\":\"1:61ef62b2bd8105b912576071cc2d00e3480da7\"}" http://0.0.0.0:1337/command/spin -H "content-type:application/x-www-form-urlencoded"
```

######Example Response
```JSON
{"ok":1,"msg":"spin-ok","request":{"command":"spin","params":{"playerToken":"1:61ef62b2bd8105b912576071cc2d00e3480da7"}},"response":{"state":{"spinsLeft":99,"spinsTotal":100,"secsLeft":385,"secsTotal":420,"winTotal":17000,"fsOn":false,"fsTrigger":null,"fsSpinsLeft":0,"fsSpinsTotal":0,"fsMxTotal":0,"fsWinTotal":0,"fsWildSymbol":null},"spin":{"window":[["W","P7","P6"],["S","W","P3"],["P2","P4","S"],["W","S","P6"],["B","P6","P3"]],"wins":{"wager":2500,"pay":17000,"profit":14500,"results":[{"symbol":"S","kind":3,"matches":1,"wilds":0,"mx":1,"pay":12500,"locations":[{"symbol":"S","reel":2,"row":1},{"symbol":"S","reel":4,"row":2},{"symbol":"S","reel":3,"row":3}]},{"symbol":"P2","kind":3,"matches":1,"wilds":2,"mx":1,"pay":2500,"locations":[{"symbol":"W","reel":1,"row":1},{"symbol":"W","reel":2,"row":2},{"symbol":"P2","reel":3,"row":1}],"line":18},{"symbol":"P4","kind":3,"matches":1,"wilds":2,"mx":1,"pay":2000,"locations":[{"symbol":"W","reel":1,"row":1},{"symbol":"W","reel":2,"row":2},{"symbol":"P4","reel":3,"row":2}],"line":10}]}},"neighbors":{"top":[{"PlayerID":"5","WinTotal":"535000"},{"PlayerID":"3","WinTotal":"313500"},{"PlayerID":"1","WinTotal":"199500"}],"near":[{"PlayerID":"5","WinTotal":"535000"},{"PlayerID":"5","WinTotal":"0"}]}}}
```

######Example Spin Error Responses
When a spin is attempted after time has run out:
```JSON
{"ok":0,"msg":"spin-fail-out-of-time","request":{"command":"spin","params":{"playerToken":"1:6e9b6f4e9458a10ca5165f846ae91a788d7c23"}}}
```
When a spin is attempted after the player has run out of spins
```JSON
{"ok":0,"msg":"spin-fail-no-spins","request":{"command":"spin","params":{"playerToken":"1:ae0815b0110affdd148e8ba2fe36b6ac9061e1"}}}
```
When a spin is attempted after the tournament the player is spinning in has ended:
```JSON
{"ok":0,"msg":"spin-fail-tournament-ended","request":{"command":"spin","params":{"playerToken":"1:ae0815b0110affdd148e8ba2fe36b6ac9061e1"}}}
```
When a spin is successful, but the leaderboard failed to update **NOTE: The spin data is still logged, and the spin should be counted as successful**
```JSON
{"ok":1,"msg":"spin-ok-leaderboard-fail","request":{"command":"spin","params":{"playerToken":"1:31f86c195d3dac4aaa9f97ce3fef59ab1d3ce4"}},"response":{"state":{"spinsLeft":91,"spinsTotal":100,"secsLeft":16,"secsTotal":420,"winTotal":396500,"fsTrigger":null,"bonusPick":null},"spin":{"window":[["W","S","P2"],["P3","P7","W"],["B","P3","S"],["S","P6","P7"],["S","P2","B"]],"wins":{"wager":2500,"pay":27000,"profit":24500,"results":[{"symbol":"S","kind":4,"matches":1,"wilds":0,"mx":1,"pay":25000,"locations":[{"symbol":"S","reel":4,"row":1},{"symbol":"S","reel":5,"row":1},{"symbol":"S","reel":1,"row":2},{"symbol":"S","reel":3,"row":3}]},{"symbol":"P3","kind":3,"matches":1,"wilds":1,"mx":1,"pay":2000,"locations":[{"symbol":"W","reel":1,"row":1},{"symbol":"P3","reel":2,"row":1},{"symbol":"P3","reel":3,"row":2}],"line":6}]}},"neighbors":{"top":[{"PlayerID":"5","WinTotal":"2437000"},{"PlayerID":"3","WinTotal":"2212500"},{"PlayerID":"6","WinTotal":"2113500"}],"near":[{"PlayerID":"5","WinTotal":"2437000"},{"PlayerID":"9","WinTotal":"373000"}]}}}
```

####Historical Offsets
The reel offsets for each spin are saved in the `database.Log_?` table (where ? is the Tournament ID the log is associated with). Currently we are on version 2, and there are some tricks to extracting the offset data.

Offset data is stored in the `ReelOffsets` collumn as binary data. There are 11 bytes, a single version / reel-count byte, and 10 bytes for the reels with each reel getting 2 bytes each.

Data stored with the version 1 paradigm can be identified by a version byte of 0x01 (1). Version 1 data will always contain five reels in the following 10 bytes.

Data stored in version 2 and greater paradigms can be identified by a version byte *greater than or equal to* 0x20 (32). This indicates that the first byte contains *both* version data, and the number of reels to be expected in the following bytes. The version is contained in the first 4 bits of data, and the number of reels is contained in the other 4 bits of data.

####Times `<host>/command/times`

| Request | Response |
|---------|----------|
| N/A | `{ times: a }` |

The `times` command does not require any parameters and returns an array of objects that that contain time and spin information for each of the currently active games. The returned objects are in the following format
```JSON
{ "id": "a",
  "name": "b",
  "startTime": "c",
  "endTime": "d",
  "spinsTotal": "e",
  "secsTotal": "f" }
```

######Example Request (curl)
```terminal
curl http://0.0.0.0:1337/command/times
```

######Example Response
```JSON
{"ok":1,"msg":"times-ok","request":{"command":"times"},"response":{"times":[{"id":1,"name":"Angry Chefs","startTime":"00:00:00","endTime":"23:59:59","spinsTotal":100,"secsTotal":360},{"id":2,"name":"Bankroll Bandits","startTime":"00:00:00","endTime":"23:59:59","spinsTotal":100,"secsTotal":420},{"id":3,"name":"Butterfly Treasures","startTime":"00:00:00","endTime":"23:59:59","spinsTotal":100,"secsTotal":420},{"id":4,"name":"Undersea World","startTime":"00:00:00","endTime":"23:59:59","spinsTotal":100,"secsTotal":420}]}}
```

####Games `<host>/command/games`

| Request | Response |
|---------|----------|
| N/A | `{ games: a }` |

The `games` command does not require any parameters and returns an array of object that contain theme and math ids for each of the currently active games formatted as follows:
```JSON
{ "id": "a",
  "name": "b",
  "theme": "c",
  "math": "d" }
```

######Example Request (curl)
```terminal
curl http://0.0.0.0:1337/command/games
```

######Example Response
```JSON
{"ok":1,"msg":"games-ok","request":{"command":"games"},"response":{"games":[{"id":1,"name":"Angry Chefs","theme":"angrychefs","math":"angrychefs"},{"id":2,"name":"Bankroll Bandits","theme":"bankrollbandits","math":"bankrollbandits"},{"id":3,"name":"Butterfly Treasures","theme":"butterflytreasures","math":"butterflytreasures"},{"id":4,"name":"Undersea World","theme":"underseaworld","math":"underseaworld"}]}}
```

####List `<host>/command/list`

| Request | Response |
|---------|----------|
| `[{ playerId: a }]` | `{ tournamentInfo: [ b... ], playerTournamentId: c }` |

The `list` command returns an array of all of the currently active tournaments, as well as the ID of the provided player's currently active tournament, if a player is provided. The tournamentInfo objects are formatted as follows:
```JSON
{ "ID":"a",
  "StartDate":"c",
  "EndDate":"d",
  "Prize":"e"}
```

######Example Request (curl)
```terminal
curl --data-urlencode "data={\"playerId\":\"1\"}" http://0.0.0.0:1337/command/list -H "content-type:application/x-www-form-urlencoded"
```

######Example Response
```JSON
{"ok":1,"msg":"list-ok","request":{"command":"list","params":{"playerId":"1"}},"response":{"tournamentInfo":[{"ID":1,"GameID":3,"StartDate":"Sat Nov 10 2012 10:00:00 GMT-0800 (PST)","EndDate":"Thu Dec 10 2015 10:25:00 GMT-0800 (PST)","Prize":"A PURPLE PONY"}],"playerTournamentId":1}}
```

####Lobby `<host>/command/lobby`

| Request | Response |
|---------|----------|
| N/A | `{ tournaments: [ a... ], games: [ b... ] }` |

The `lobby` command returns information about tournaments and games that are required for the game lobby. The tournaments field contains an array of objects that represent currently active tournaments, and the games field contains an array of objects that represent the currently active games. The tournament objects are formatted as follows:
```JSON
{ "id": "a",
  "startTime": "b",
  "endTime": "c",
  "prize": "d" }
```
and the game objects are formatted:
```JSON
{ "gameId": "a",
  "name": "b",
  "theme": "c",
  "spinsTotal": "d",
  "secsLeft": "e",
  "secsTotal": "e" }
```

######Example Request (curl)
```Terminal
curl http://0.0.0.0:1337/command/lobby
```

######Example Response
```JSON
{"ok":1,"msg":"lobby-list-ok","request":{"command":"lobby-list"},"response":{"tournaments":[{"id":1,"startTime":"Sat Nov 10 2012 10:15:00 GMT-0800 (PST)","endTime":"Thu Dec 10 2015 10:25:00 GMT-0800 (PST)","prize":"A PURPLE PONY"}],"games":[{"gameId":1,"name":"Angry Chefs","theme":"angrychefs","spinsTotal":100,"secsLeft":360,"secsTotal":360},{"gameId":2,"name":"Bankroll Bandits","theme":"bankrollbandits","spinsTotal":100,"secsLeft":420,"secsTotal":420},{"gameId":3,"name":"Butterfly Treasures","theme":"butterflytreasures","spinsTotal":100,"secsLeft":420,"secsTotal":420},{"gameId":4,"name":"Undersea World","theme":"underseaworld","spinsTotal":100,"secsLeft":420,"secsTotal":420}]}}
```

####Rank `<host>/command/rank`

| Request | Response |
|---------|----------|
| `{ slotPlayerId: a }` | `{ rank: b, lastRank: c, winTotal: d }` |

The `rank` command returns the provided player's current rank in their current session based on the model of Standard Competition Ranking.

######Example Request (curl)
```terminal
curl --data-urlencode "data={\"slotPlayerId\":\"1\"}" http://0.0.0.0:1337/command/rank -H "content-type:application/x-www-form-urlencoded"
```

######Example Response
```JSON
{"ok":1,"msg":"rank-ok","request":{"command":"rank","params":{"slotPlayerId":"1"}},"response":{"rank":8,"lastRank":0,"winTotal":"95500"}}
```

####Ranks `<host>/command/ranks`

| Request | Response |
|---------|----------|
| `{ tournamentId: a[, playerId: b] }` | `{ tournamentId: a, you: c, ranks: [ d, e, ..., r ] }` |

The `ranks` command returns the top 15 players' rank and score and can optionally return a specific player's rank and score if one is provided. The objects representing a player's rank and score are formatted as follows:
```JSON
{ "rank": "a",
  "winTotal": "b" }
```

######Example Request (curl)
```terminal
curl --data-urlencode "data={\"tournamentId\":1,\"playerId\":\"1\"}" http://0.0.0.0:1337/command/ranks -H "content-type:application/x-www-form-urlencoded"
```

######Example Response
```JSON
{"ok":1,"msg":"ranks-ok","request":{"command":"ranks","params":{"tournamentId":1,"playerId":"1"}},"response":{"tournamentId":1,"you":{"rank":8,"winTotal":"95500"},"ranks":[{"PlayerID":"5","WinTotal":"535000"},{"PlayerID":"3","WinTotal":"313500"},{"PlayerID":"1","WinTotal":"199500"},{"PlayerID":"2","WinTotal":"196000"},{"PlayerID":"3","WinTotal":"174000"},{"PlayerID":"3","WinTotal":"147000"},{"PlayerID":"1","WinTotal":"132500"},{"PlayerID":"1","WinTotal":"95500"},{"PlayerID":"4","WinTotal":"31500"},{"PlayerID":"2","WinTotal":"22000"},{"PlayerID":"5","WinTotal":"17000"},{"PlayerID":"5","WinTotal":"0"}]}}
```

####Scores `<host>/command/scores`
| Request | Response |
|---------|----------|
| `{ playerId: a, numTournaments: b}` | |

###Backend Commands
These commands can only be accessed from the Kizzang API environment defined in [slotserver.xml](slotserver.xml) (as long as debug support is turned off)

####RegToken `<host>/bcommand/regToken`

| Request | Response |
|---------|----------|
| `{ tournamentId: a, playerId: b, gameId: c, appToken: d, apiKey: e[, screenName: f, fbId: g]}` | `{ playerId: b, playerToken: h, tournamentId: i, gameId: j, betTotal: k, state: l, neighbors: l[, timeToSpin: m] }` |

The special `regToken` command is used to register a player into the provided tournament and begin their session. This command will return the provided player's current tournament and game, as well as state information and information on neighboring players. The data in the `state` field is the same as in the `spin` command, save a few notable exceptions. The `fsTrigger` field is never returned, the other "fs" fields are always returned but they will always have 0 or null values in non-fs games, and the bonusPick is never returned. For information on how the `neighbors` field is formatted, see `spin`, there is no difference between the two commands for the `neighbors` field.

If this is called while a player's current session is still ongoing (that is, the player still has time and spins remaining), then a special message `regToken-rejoin-success` will be returned, as well as the player's current active play token tournament, and game. The message `regToken-success-update` is given when the registering player already exists, and the message `regToken-success-insert` is given when a new player registers for the first time. If, for some reason, the leaderboard check failed, the registration will still be successful, but the message will be appended by `-leaderboard-fail`. If the player has already registered, but has not spun yet, the `timeToSpin` field will be included in the response, which will contain the number of seconds the player has left to make their first spin.

**NOTE: The "betTotal" field is currently hard-coded to return the value 25**

When a new session is created a post will be made to the Kizzang API. The specific API is dependent on the current environment defined in [slotserver.xml](slotserver.xml). This post shall contain the body `"gameType=SlotTournament"` and two custom headers, `TOKEN` and `X-API-KEY`. The `TOKEN` header will contain the appToken provided in the initial request, and the `X-API-KEY` will contain a the apiKey provided in the initial request. This request will timeout after a certain number of milliseconds defined in [slotserver.xml](slotserver.xml) (defaulting to 5000), if the request times out then the message `regToken-fail-API-timeout` will be returned and the registration attempt will fail. *It is required that the Kizzang API returns a 2xx Successful status code for token registration to succeed.* If the post to the Kizzang API fails for a reason other then timeout, the `regToken-fail-API-failure` message will be returned.

######Example Request (curl)
```terminal
curl --data-urlencode "data={\"tournamentId\":1,\"playerId\":30,\"gameId\":1,\"appToken\":\"TestToken\",\"apiKey\":\"TestKey\",\"screenName\":\"TestN\",\"fbId\":\"000000000\"}" http://0.0.0.0:1337/bcommand/regToken -H "content-type:application/x-www-form-urlencoded"
```

######Example Response
```JSON
{"ok":1,"msg":"regToken-success-insert","request":{"command":"bcommand/regToken","params":{"tournamentId":1,"playerId":30,"gameId":1,"appToken":"TestToken","apiKey":"TestKey","screenName":"TestN","fbId":"000000000"}},"response":{"playerId":30,"playToken":"1:4576c942340c50e9cefa6f522e0331997f19e3","tournamentId":1,"gameId":1,"betTotal":25,"state":{"spinsLeft":100,"spinsTotal":100,"secsLeft":360,"secsTotal":360,"winTotal":0},"neighbors":{"top":[{"PlayerID":"1","WinTotal":"9902567","ScreenName":"naadrm"},{"PlayerID":"3","WinTotal":"8080034","ScreenName":"naadrm","FacebookID":"000000000"},{"PlayerID":"1","WinTotal":"2796034","ScreenName":"naadrm"}],"near":[{"PlayerID":"1","WinTotal":"22521","ScreenName":"naadrm"},{"PlayerID":30,"WinTotal":0,"ScreenName":"TestN","FacebookID":"000000000"}]}}}
```

####TournamentAdd `<host>/bcommand/tournamentAdd`

This Command has been removed

####TournamentDelete `<host>/bcommand/tournamentDelete`

This command has been removed

####Winners `<host>/bcommand/winners`
| Request | Response |
|---------|----------|
| `{ tournamentId: a }` | `{ winners: [ b... ] }` |

The special `winners` command is used to determine what players won a specific tournament. The requested tournament must have expired, or a `winners-fail-invalid-tournament` error will be returned. The response information will always be an array of player data objects formatted as follows. This array will only contain more than one object when more than one player holds first place.
```JSON
{ "PlayerID":"a",
   "WinTotal":"b" }
```

######Example Request (curl)
```terminal
curl --data-urlencode "data={\"tournamentId\":1}" http://0.0.0.0:1337/bcommand/winners -H "content-type:application/x-www-form-urlencoded"
```

######Example Response
```JSON
{"ok":1,"msg":"winners-ok","request":{"command":"bcommand/onWinners","params":{"tournamentId":1}},"response":{"winners":[{"PlayerID":"5","WinTotal":"535000"}]}}
```

####Timing `<host>/bcommand/timing`
| Request | Response |
|---------|----------|
| `[{ queryLimit: a }]` | `{ servers: [ b... ] }` |

The special `timing` command is a debug command that will return the current time of a number of servers determined by the queryLimit. The queryLimit request field will determine how many previous servers from the SlotServer table will be queried, and defaults to 100 if it is not provided.

The objects within the servers array are formatted as follows
```JSON
{ "host": "a",
  "port": "b",
  "date": "c" }
```

######Example Request (curl)
```terminal
curl http://0.0.0.0:1337/bcommand/timing
```

######Example Response
```JSON
{"ok":1,"msg":"timing-success","request":{"command":"timing","params":null},"response":{"servers":[{"host":"ubuntu","port":1337,"date":"Fri Dec 05 2014 04:27:13 GMT-0800 (PST)"}]}}
```

####OldTournaments `host/bcommand/oldTournaments`
| Request | Response |
|---------|----------|
| `[{ offset: a }]` | `{ tournaments: [ b... ] }` **OR** `{ maxOffset: c }` |

The special `oldTournaments` command will return a paged list of expired tournaments with 10 elements per page, based on a provided offset. If no offset is provided then an offset of 0 will be presumed. If the offset provided is greater than the maximum available offset, then the message `oldTournaments-fail-out-of-bounds-offset` will be returned and the response will contain the maximum allowed offset `maxOffset` *instead of* an array of tournaments. If the command returns the final page of data, then the special message `oldTournaments-ok-end-of-list` will be returned. Note that he "offset" value does *not* represent the page number, but is the starting index from which the page will be generated.

######Example Request (curl)
```terminal
curl --data-urlencode "data={\"offset\":0}" http://0.0.0.0:1337/bcommand/oldTournaments -H "content-type:application/x-www-form-urlencoded"
```

######Example Response
```JSON
{"ok":1,"msg":"oldTournaments-ok","request":{"command":"oldTournaments","params":{"offset":0}},"response":{"tournaments":[{"ID":3,"StartDate":"Sat Nov 10 2012 10:15:00 GMT-0800 (PST)","EndDate":"Tue Dec 30 2014 10:25:00 GMT-0800 (PST)","PrizeList":"\"1\""},{"ID":4,"StartDate":"Sat Nov 10 2012 10:15:00 GMT-0800 (PST)","EndDate":"Mon Dec 29 2014 10:25:00 GMT-0800 (PST)","PrizeList":"\"2\""},{"ID":5,"StartDate":"Sat Nov 10 2012 10:15:00 GMT-0800 (PST)","EndDate":"Sat Dec 27 2014 10:25:00 GMT-0800 (PST)","PrizeList":"\"3\""},{"ID":6,"StartDate":"Sat Nov 10 2012 10:15:00 GMT-0800 (PST)","EndDate":"Fri Dec 26 2014 10:25:00 GMT-0800 (PST)","PrizeList":"\"4\""},{"ID":7,"StartDate":"Sat Nov 10 2012 10:15:00 GMT-0800 (PST)","EndDate":"Thu Dec 25 2014 10:25:00 GMT-0800 (PST)","PrizeList":"\"5\""},{"ID":8,"StartDate":"Sat Nov 10 2012 10:15:00 GMT-0800 (PST)","EndDate":"Wed Dec 24 2014 10:25:00 GMT-0800 (PST)","PrizeList":"\"6\""},{"ID":9,"StartDate":"Sat Nov 10 2012 10:15:00 GMT-0800 (PST)","EndDate":"Tue Dec 23 2014 10:25:00 GMT-0800 (PST)","PrizeList":"\"7\""},{"ID":10,"StartDate":"Sat Nov 10 2012 10:15:00 GMT-0800 (PST)","EndDate":"Mon Dec 22 2014 10:25:00 GMT-0800 (PST)","PrizeList":"\"8\""},{"ID":11,"StartDate":"Sat Nov 10 2012 10:15:00 GMT-0800 (PST)","EndDate":"Sun Dec 21 2014 10:25:00 GMT-0800 (PST)","PrizeList":"\"9\""},{"ID":12,"StartDate":"Sat Nov 10 2012 10:15:00 GMT-0800 (PST)","EndDate":"Sat Dec 20 2014 10:25:00 GMT-0800 (PST)","PrizeList":"\"10\""}]}}
```


Configuration
=============

Server configuration is conveniently handled in the [slotserver.xml](slotserver.xml) file. Usage information is contained in the file itself.


Development environment
=======================

This project using `Vagrant` and `Chef Solo` for create development environment

##### Edit Vagrantfile

1. Make sure that you are using correct the  path to `kizzangChef` p4's depot (Latest version)

		CHEF_PATH = "/Development/kizzangChef"

2. The IP of Vagrant box

		config.vm.network "private_network", ip: "192.168.33.103"

##### Run Vagrant

		vagrant up		
		

##### Run the webapp

		http://192.168.33.103:1337