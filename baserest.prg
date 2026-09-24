* Parent class for REST API classes.

#define ccCRLF	chr(13) + chr(10)
#define ccTAB	chr(9)

define class BaseREST as Custom
	cErrorMessage = ''
		&& the message for any error that occurred
	cLogFile      = 'restlog.txt'
		&& the path for the log file
	lLogging      = .F.
		&& set to .T. to log information about the REST call to a text file
	cVersion      = '2026.09.24'
		&& the version number

	protected aHeaders[1, 2], cHTTPClass, cHTTPLibrary, cINIFile, cINISection, ;
		cPostData, cQueryString, cResultCode, cURL, lUseJSON, nTimeZoneOffset, oResponse
	aHeaders        = ''
		&& the request headers to use
	cHTTPClass      = 'WinHttp.WinHttpRequest.5.1'
		&& the class for the HTTP object; set it to "wwHTTPREST" and
		&& cHTTPLibrary to "wwHTTPREST.prg" to use a subclass of wwHTTP
	cHTTPLibrary    = ''
		&& the library for the class specified in cHTTPClass
	cINIFile        = 'api.ini'
		&& the name of the INI file containing settings
	cINISection     = ''
		&& the section in the INI file containing settings for this class
	cPostData       = ''
		&& the data to post
	cQueryString    = ''
		&& the query string to add to the URL
	cResultCode     = ''
		&& the result of the API call
	lUseJSON        = .T.
		&& .T. to specify a Content-Type header of application/json
	cURL            = ''
		&& the URL to call
	nTimeZoneOffset = -1
		&& the timezone offset from UTC
	oResponse       = NULL
		&& the response object

* Set up the class.

	function Init(tcINIFile)
		local lcLogFile, ;
			lcExt

* Set the INI file if one was passed.

		if vartype(tcINIFile) = 'C' and not empty(tcINIFile) and file(tcINIFile)
			This.cINIFile = tcINIFile
		endif vartype(tcINIFile) = 'C' ...

* Get some values from the INI file.

		if not empty(This.cINIFile) and not empty(This.cINISection)
			This.cURL     = ReadINI(This.cINIFile, This.cINISection, 'URL',     This.cURL)
			This.lLogging = ReadINI(This.cINIFile, This.cINISection, 'Logging', iif(This.lLogging, 'Y', 'N')) = 'Y'
			This.cLogFile = ReadINI(This.cINIFile, This.cINISection, 'LogFile', This.cLogFile)
		else

* Set cLogFile to itself so the Assign method fires.

			This.cLogFile = This.cLogFile
		endif not empty(This.cINIFile) ...
	endfunc

* Add a timestamp to the log file.

	procedure cLogFile_Assign(tcLogFile)
		local lcLogFile, ;
			lcExt
		lcLogFile     = evl(tcLogFile, This.cLogFile)
		lcExt         = justext(lcLogFile)
		This.cLogFile = stuff(lcLogFile, at('.' + lcExt, lcLogFile), 0, dtos(date()))
	endproc

* Add a post key.

	protected procedure AddPostKey(tcKey, tuValue)
		local lcValue
		lcValue = transform(tuValue)
		do case
			case pcount() = 0
				This.cPostData = ''
			case empty(tcKey)
				This.cPostData = This.cPostData + lcValue
			otherwise
				This.cPostData = This.cPostData + iif(empty(This.cPostData), '', '&') + ;
					tcKey + '=' + This.HTMLEncode(lcValue)
		endcase
	endproc

* Add a query string parameter.

	protected procedure AddQueryString(tcKey, tuValue)
		if pcount() = 0
			This.cQueryString = ''
		else
			This.cQueryString = This.cQueryString + iif(empty(This.cQueryString), '?', '&') + ;
				iif(empty(tcKey), '', tcKey + '=') + This.HTMLEncode(transform(tuValue))
		endif pcount() = 0
	endproc

* Add a request header.

	protected procedure AddRequestHeader(tcKey, tcValue)
		local lnHeader
		if pcount() = 0
			dimension This.aHeaders[1, 2]
			This.aHeaders = ''
		else
			lnHeader = ascan(This.aHeaders, tcKey, -1, -1, 1, 15)
			if lnHeader = 0
				lnHeader = iif(empty(This.aHeaders[1, 2]), 1, alen(This.aHeaders, 1) + 1)
				dimension This.aHeaders[lnHeader, 2]
				This.aHeaders[lnHeader, 1] = tcKey
			endif lnHeader = 0
			This.aHeaders[lnHeader, 2] = tcValue
		endif pcount() = 0
	endproc

* Get a configured HTTP object.

	protected function GetHTTPObject(tcURL, tcVerb)
		local loHTTP, ;
			lcVerb, ;
			loException as Exception
		try
			if empty(This.cHTTPLibrary)
				loHTTP = createobject(This.cHTTPClass)
			else
				loHTTP = newobject(This.cHTTPClass, This.cHTTPLibrary)
			endif empty(This.cHTTPLibrary)
			lcVerb = evl(tcVerb, 'POST')
			loHTTP.Open(lcVerb, tcURL + This.cQueryString, .F.)
			if This.lUseJSON
				This.AddRequestHeader('Content-Type', 'application/json; charset=UTF-8')
				This.AddRequestHeader('Accept',       'application/json')
			endif This.lUseJSON
		catch to loException
			loHTTP = NULL
		endtry
		return loHTTP
	endfunc

* Call the API.

	protected function GetResult(toHTTP)
		local lnI, ;
			lcKey, ;
			lcValue, ;
			lcResult, ;
			loException as Exception
		lnHeaders = alen(This.aHeaders, 1)
		for lnI = 1 to lnHeaders
			lcKey   = This.aHeaders[lnI, 1]
			lcValue = This.aHeaders[lnI, 2]
			toHTTP.SetRequestHeader(lcKey, lcValue)
		next lnI
		try
			toHTTP.Send(This.cPostData)
			lcResult = toHTTP.ResponseText
			This.cResultCode = transform(toHTTP.Status)
		catch to loException
			This.cErrorMessage = loException.Message
			lcResult = ''
		endtry

* Clear the post data, headers, and query string.

		This.AddPostKey()
		This.AddRequestHeader()
		This.AddQueryString()
		return lcResult
	endfunc

* Log the REST call.

	protected function LogRESTCall(tcMessage)
		local lcExt
		if This.lLogging
			strtofile(tcMessage + ccCRLF, This.cLogFile, .T.)
		endif This.lLogging
	endfunc

* Perform the API call. This method isn't called directly from a client but is instead called
* from specific methods in a subclass.

	protected function APICall(tcVerb, tcSuccessCode, tcTask, toParameter)
		local lcQueryString, ;
			lcPostData, ;
			lcJSON, ;
			lcURL, ;
			loHTTP, ;
			lcHeaders, ;
			lnI, ;
			lcResult, ;
			lcFormattedResult, ;
			loJSON, ;
			llReturn

* Clear the error message.

		This.cErrorMessage  = ''

* Save values for logging since they get cleared.

		lcQueryString = This.cQueryString
		lcPostData    = This.cPostData

* Create JSON for the parameters.

		lcJSON = ''
		if vartype(toParameter) = 'O'
			lcJSON = toParameter.GetJSON()
			This.AddPostKey('', lcJSON)
			lcJSON = This.FormatJSON(lcJSON)
		endif vartype(toParameter) = 'O'

* Create the HTTP objects and save the headers for logging.

		lcURL     = This.cURL + evl(tcTask, '')
		loHTTP    = This.GetHTTPObject(lcURL, tcVerb)
		lcHeaders = ''
		for lnI = 1 to alen(This.aHeaders, 1)
			lcHeaders = lcHeaders + iif(empty(lcHeaders), '', ccCRLF + ccTAB) + This.aHeaders[lnI, 1] + ': ' + This.aHeaders[lnI, 2]
		next lnI

* Do the REST call.

		lcResult = This.GetResult(loHTTP)

* If we're logging, format the result.

		if This.lLogging and not empty(lcResult)
			lcFormattedResult = This.FormatJSON(lcResult)
		else
			lcFormattedResult = lcResult
		endif This.lLogging ...

* Deserialize the JSON if any was returned.

		loJSON = NULL
		do case
			case empty(lcResult)
			case not left(lcResult, 1) $ '{['
				This.cErrorMessage = lcResult
			otherwise
				loJSON = This.DeserializeJSON(lcResult)
		endcase

* Return .T. if we have a valid result code. If we do, save the JSON object and handle
* the response. If not, handle errors.

		llReturn = This.cResultCode $ tcSuccessCode
		do case
			case llReturn
				This.oResponse = loJSON
				llReturn       = This.HandleResponse(loJSON)
			case vartype(loJSON) = 'O'
				This.oResponse = NULL
				This.HandleErrors(loJSON)
			case empty(This.cErrorMessage)
				This.cErrorMessage = 'Result code ' + This.cResultCode
		endcase
		This.LogRESTCall(ccCRLF + ;
			transform(datetime()) + ': REST call to ' + lcURL + lcQueryString + ccCRLF + ;
			'Verb = ' + tcVerb + ccCRLF + ;
			'Headers = ' + lcHeaders + ccCRLF + ;
			iif(empty(lcJSON) and not empty(lcPostData), 'Post data = ' + lcPostData + ccCRLF, '') + ;
			'Result code = ' + This.cResultCode + ;
			iif(empty(lcJSON), '', ccCRLF + 'JSON body = ' + lcJSON) + ;
			iif(empty(lcResult), '', ccCRLF + 'Result = ' + lcFormattedResult) + ;
			iif(empty(This.cErrorMessage), '', ccCRLF + 'Error message = ' + This.cErrorMessage))
		return llReturn
	endfunc

* Handle errors. Abstract in this class.

	protected procedure HandleErrors(toJSON)
	endproc

* Handle the response. Abstract in this class.

	protected procedure HandleResponse(toJSON)
		return .T.
	endproc

* HTML encode a value.

	protected function HTMLEncode(tcValue)
		local lcReturn, ;
			lnI, ;
			lcChar
		lcReturn = ''
		for lnI = 1 to len(trim(tcValue))
			lcChar = substr(tcValue, lnI, 1)
			do case
				case atc(lcChar, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~') > 0
					lcReturn = lcReturn + lcChar
				case lcChar = ' '
					lcReturn = lcReturn + '%20'
				otherwise
					lcReturn = lcReturn + '%' + right(transform(asc(lcChar), '@0'), 2)
			endcase
		next lnI
		return lcReturn
	endfunc

* Convert a UTC datetime to local.

	protected function ConvertUTCToLocal(ttValue)
		local lcTimeZone, ;
			lnID, ;
			lnStandardOffset, ;
			lnDaylightOffset, ;
			ltValue

* If we haven't done this before, get the offset between UTC and local.

		if This.nTimeZoneOffset = -1
			#define TIME_ZONE_SIZE  172
			declare integer GetTimeZoneInformation in Win32API ;
				string @lpTimeZoneInformation
			lcTimeZone = replicate(chr(0), TIME_ZONE_SIZE)
			lnID       = GetTimeZoneInformation(@lcTimeZone)

* Determine the standard and daylight time offset.
 
			lnStandardOffset = ctobin(substr(lcTimeZone,   1, 4), '4RS')
			lnDaylightOffset = ctobin(substr(lcTimeZone, 169, 4), '4RS')

* Determine the total offset based on whether the computer is on daylight time
* or not.
 
			if lnID = 2  && daylight time
				This.nTimeZoneOffset = (lnStandardOffset + lnDaylightOffset) * 60
			else   && standard time
				This.nTimeZoneOffset = lnStandardOffset * 60
			endif lnID = 2
		endif This.nTimeZoneOffset = -1
		ltValue = ttValue - This.nTimeZoneOffset
		return ltValue
	endfunc

* Returns formatted JSON.

	protected function FormatJSON(tcJSON)
		local lcJSON
		lcJSON = JSONFormat(tcJSON)
		return lcJSON
	endfunc

* Deserialize JSON into an object.

	protected function DeserializeJSON(tcJSON)
		local loJSON
		loJSON = nfJSONRead(tcJSON)
		return loJSON
	endfunc
enddefine

* Parent class for REST API classes using authorization tokens.

define class TokenBasedREST as BaseREST
	protected cAuthorizationURL, cTokenType, cTokenTable, cAPIName
	cAuthorizationURL = ''
		&& the URL to get an authentication token from
	cTokenType        = 'Bearer'
		&& the type of Authorization header
	cTokenTable       = 'Token.dbf'
		&& the path for the token table
	cAPIName          = ''
		&& the name of this API

	function Init
		dodefault()
		This.cAPIName = juststem(program(program(-1) - 1))
		if not empty(This.cINIFile) and not empty(This.cINISection)
			This.cAuthorizationURL = ReadINI(This.cINIFile, This.cINISection, 'AuthorizationURL')
		endif not empty(This.cINIFile) ...
	endfunc

* Get the authentication token.

	protected function GetAuthenticationToken
		local loToken

* Create the token table if necessary.

		do case
			case file(This.cTokenTable)
			case not This.CreateTokenTable()
				return ''
		endcase

* If the authentication token doesn't exist or is expired, get a new one.

		loToken = This.FindToken('Authentication')
		if empty(loToken.Token) or loToken.Expires < datetime()
			This.GetNewAuthenticationToken(loToken)
			if not empty(loToken.Token)
				This.SaveToken('Authentication', loToken.Token, loToken.Expires)
			endif not empty(loToken.Token)
		endif empty(Token) ...
		return loToken.Token
	endfunc

* Create the token table.

	protected function CreateTokenTable
		local lnSelect, ;
			llReturn, ;
			loException as Exception
		lnSelect = select()
		try
			create table (This.cTokenTable) ;
				( ;
				API C(20), ;
				Type C(15), ;
				Expires T, ;
				Token M ;
				)
			use
			llReturn = .T.
		catch to loException
			This.cErrorMessage = loException.Message
		endtry
		select (lnSelect)
		return llReturn
	endfunc

* Finds the specified token for this API.

	protected function FindToken(tcType, tlNoClose)
		local lnSelect, ;
			loToken
		lnSelect = select()
		if used('TokenTable')
			select TokenTable
		else
			select 0
			use (This.cTokenTable) again shared alias TokenTable
		endif used('TokenTable')
		locate for API = This.cAPIName and upper(Type) = upper(tcType)
		if not found()
			insert into (This.cTokenTable) (API, Type) values (This.cAPIName, tcType)
		endif not found()
		scatter name loToken memo
		loToken.API   = trim(loToken.API)
		loToken.Type  = trim(loToken.Type)
		loToken.Token = trim(loToken.Token)
		if not tlNoClose
			use
		endif not tlNoClose
		select (lnSelect)
		return loToken
	endfunc

* Save the specified token.

	protected procedure SaveToken(tcType, tcToken, ttExpires)
		local loToken
		loToken = This.FindToken(tcType, .T.)
		replace Token with tcToken, ;
				Expires with ttExpires ;
			in TokenTable
		use in TokenTable
	endproc

* Gets a new authentication token. Abstract in this class.

	protected procedure GetNewAuthenticationToken
		return ''
	endproc

* Add an authentication header before we perform the API call.

	protected function APICall(tcVerb, tcSuccessCode, tcTask, toParameter)
		local lcToken, ;
			llReturn
		This.AddRequestHeader()
		lcToken = This.GetAuthenticationToken()
		if not empty(lcToken)
			This.AddRequestHeader('Authorization', This.cTokenType + ' ' + lcToken)
			llReturn = dodefault(tcVerb, tcSuccessCode, tcTask, toParameter)
		endif not empty(lcToken)
		return llReturn
	endfunc
enddefine

* Base parameter object.

define class BaseParameters as Custom
	dimension aProperties[1]
		&& can't be protected because BaseCollection may need it

* Get the JSON for the parameters.

	function GetJSON
		local lcJSON
		dimension This.aProperties[1]
		This.aProperties[1] = ''

* Ignore base class properties and aProperties.

		This.AddPropertyToList('aProperties',     , .T.)
		This.AddPropertyToList('Application',     , .T.)
		This.AddPropertyToList('BaseClass',       , .T.)
		This.AddPropertyToList('Class',           , .T.)
		This.AddPropertyToList('ClassLibrary',    , .T.)
		This.AddPropertyToList('Comment',         , .T.)
		This.AddPropertyToList('ControlCount',    , .T.)
		This.AddPropertyToList('Controls',        , .T.)
		This.AddPropertyToList('Height',          , .T.)
		This.AddPropertyToList('HelpContextID',   , .T.)
		This.AddPropertyToList('Left',            , .T.)
		This.AddPropertyToList('Name',            , .T.)
		This.AddPropertyToList('Objects',         , .T.)
		This.AddPropertyToList('Parent',          , .T.)
		This.AddPropertyToList('ParentClass',     , .T.)
		This.AddPropertyToList('Picture',         , .T.)
		This.AddPropertyToList('Tag',             , .T.)
		This.AddPropertyToList('Top',             , .T.)
		This.AddPropertyToList('WhatsThisHelpID', , .T.)
		This.AddPropertyToList('Width',           , .T.)

* Handle additional properties.

		This.GetProperties()

* Serialize ourselves and process the JSON as necessary.

		lcJSON = This.SerializeJSON()
		lcJSON = This.ProcessJSON(lcJSON)
		return lcJSON
	endfunc

* Add (or update) a property in This.aProperties. tcMember is a comma-delimited
* list of the names of the member objects this property applies to; use the name
* of the parameters class if it applies to the class (tcMember is ignored if
* tlIgnore is .T.). tnHowToHandle is how to handle the property if its value is
* empty: 0 = include it as is in the JSON, 1 = use null as the value, 2 = omit
* the property from the JSON.

	protected procedure AddPropertyToList(tcProperty, tcMember, tlIgnore, tnHowToHandle)
		local lnProperty
		lnProperty = ascan(This.aProperties, tcProperty, -1, -1, 1, 15)
		if lnProperty = 0
			lnProperty = iif(empty(This.aProperties[1]), 1, alen(This.aProperties, 1) + 1)
			dimension This.aProperties[lnProperty, 4]
		endif lnProperty = 0
		This.aProperties[lnProperty, 1] = tcProperty
		This.aProperties[lnProperty, 2] = evl(tcMember, This.Name)
		This.aProperties[lnProperty, 3] = tlIgnore
		This.aProperties[lnProperty, 4] = evl(tnHowToHandle, 0)
	endproc

* Handle certain properties specially; abstract in this class. Typically a subclass
* will call AddPropertyToList for each specially handled property.

	protected procedure GetProperties
	endproc

* Process the generated JSON (abstract in this class).

	protected function ProcessJSON(tcJSON)
		return tcJSON
	endfunc

* Serialize ourselves into JSON.

	protected function SerializeJSON()
		local laProperties[1], ;
			lcJSON
		acopy(This.aProperties, laProperties)
		lcJSON = nfJSONCreate(This, , , , , .T., @laProperties)
		return lcJSON
	endfunc
enddefine

* Base collection object (used when we need a collection of parameters passed to APICall).

define class BaseCollection as Collection
	function GetJSON
		local lcJSON, ;
			laProperties[1]
		lcJSON = This.Item[1].GetJSON()
			&& do this so aProperties is set up
		acopy(This.Item[1].aProperties, laProperties)
		lcJSON = nfJSONCreate(This, , , , , .T., @laProperties)
		return lcJSON
	endfunc
enddefine
