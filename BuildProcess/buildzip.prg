lcFiles = '..\baserest.prg,..\foxcryptong.prg,' + ;
	'..\jsonformat.prg,..\nfjsoncreate.prg,' + ;
	'..\nfjsonread.prg,..\readini.prg,' + ;
	'..\wwhttprest.prg,..\writeini.prg'
loZIP = newobject('VFPXZip', 'VFPXZip.prg')
loZIP.Zip(lcFiles, '..\FoxGet\Source.zip', .T.)
if empty(loZIP.cErrorMessage)
	messagebox('Source.zip created')
else
	messagebox(loZIP.cErrorMessage)
endif empty(loZIP.cErrorMessage)
