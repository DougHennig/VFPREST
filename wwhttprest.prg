* Subclass of wwHTTP that has a similar interface to WinHttp.WinHttpRequest.5.1.

define class wwHTTPRest as wwHTTP of wwHTTP.prg
	cURL         = ''
	ResponseText = ''
	Status       = ''

	function Init
		do wwHTTP
		dodefault()
	endfunc
	
	function Open(tcVerb, tcURL, tlSync)
		This.cURL      = tcURL
		This.cHTTPVerb = tcVerb
	endfunc

	function SetRequestHeader(tcKey, tcValue)
		This.AddHeader(tcKey, tcValue)
	endfunc

	function Send(tcPostData)
		This.cPostBuffer  = tcPostData
		This.ResponseText = This.HTTPGet(This.cURL)
		This.Status       = This.cResultCode
	endfunc
enddefine
