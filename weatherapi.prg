local loAPI, ;
	llUS, ;
	llSuccess
llUS  = .F.

loAPI = createobject('WeatherAPI')
loAPI.lLogging = .F.
erase (loAPI.cLogFile)

llSuccess = loAPI.GetWeather(49.888026, -97.138923, llUS)
if llSuccess
	messagebox('Weather = ' + loAPI.cWeather + chr(13) + ;
		'Temperature = ' + transform(loAPI.nTemperature) + iif(llUS, 'F', 'C') + chr(13) + ;
		'Wind speed = ' + transform(loAPI.nWindSpeed) + iif(llUS, ' mph', ' kph') + chr(13) + ;
		'Precipitation = ' + transform(loAPI.nPrecipitation) + iif(llUS, '"', 'mm'))
else
	messagebox(loAPI.cErrorMessage)
endif llSuccess

if loAPI.lLogging
	modify file (loAPI.cLogFile) nowait
endif loAPI.lLogging


define class WeatherAPI as BaseREST of BaseREST.prg

* Custom properties.

	nTemperature   = 0
	nWindSpeed     = 0
	nPrecipitation = 0
	cWeather       = ''
		&& a description of the weather, such as "Clear sky" or "Overcast"

* Override parent properties.

	cURL = 'https://api.open-meteo.com/v1/forecast'
*	cHTTPClass   = 'wwHTTPREST'
*	cHTTPLibrary = 'wwHTTPREST.prg'

* Get the current weather conditions.

	function GetWeather(tnLatitude, tnLongitude, tlUS)
		local llReturn, ;
			lcWeatherCode
		This.AddQueryString('latitude',  tnLatitude)
		This.AddQueryString('longitude', tnLongitude)
		This.AddQueryString('current',   'weather_code,temperature_2m,wind_speed_10m,precipitation')
		if tlUS
			This.AddQueryString('temperature_unit',   'fahrenheit')
			This.AddQueryString('wind_speed_unit',    'mph')
			This.AddQueryString('precipitation_unit', 'inch')
		endif tlUS
		llReturn = This.APICall('GET', '200')
		if llReturn
			This.nTemperature   = This.oResponse.Current.Temperature_2m
			This.nWindSpeed     = This.oResponse.Current.Wind_Speed_10m
			This.nPrecipitation = This.oResponse.Current.Precipitation
			lcWeatherCode       = This.oResponse.Current.Weather_Code
			This.cWeather       = This.GetWeatherDescription(lcWeatherCode)
		endif llReturn
		return llReturn
	endfunc

* Get the weather description from the code: see https://open-meteo.com/en/docs

	protected function GetWeatherDescription(tnCode)
		local lcDescription
		do case
			case tnCode = 0
				lcDescription = 'Clear sky'
			case tnCode = 1
				lcDescription = 'Mainly clear'
			case tnCode = 2
				lcDescription = 'Partly cloudy'
			case tnCode = 3
				lcDescription = 'Overcast'
			case tnCode = 51
				lcDescription = 'Drizzle: light'
			case tnCode = 53
				lcDescription = 'Drizzle: moderate'
			case tnCode = 55
				lcDescription = 'Drizzle: dense'
			case tnCode = 56
				lcDescription = 'Freezing Drizzle: light'
			case tnCode = 57
				lcDescription = 'Freezing Drizzle: dense'
			case tnCode = 61
				lcDescription = 'Rain: light'
			case tnCode = 63
				lcDescription = 'Rain: moderate'
			case tnCode = 65
				lcDescription = 'Rain: heavy'
			case tnCode = 66
				lcDescription = 'Freezing Rain: light'
			case tnCode = 67
				lcDescription = 'Freezing Rain: heavy'
			case tnCode = 71
				lcDescription = 'Snow fall: light'
			case tnCode = 73
				lcDescription = 'Snow fall: moderate'
			case tnCode = 75
				lcDescription = 'Snow fall: heavy'
*** Note: there are additional codes listed at https://open-meteo.com/en/docs
			otherwise
				lcDescription = 'Weather code ' + transform(tnCode)
		endcase
		return lcDescription
	endfunc

* Handle errors.

	protected procedure HandleErrors(toJSON)
		if pemstatus(toJSON, 'error', 5) and toJSON.error
			This.cErrorMessage = toJSON.Reason
		endif pemstatus(toJSON, 'error', 5) ...
	endproc
enddefine
