local loAPI, ;
	loParameter, ;
	llSuccess

loAPI = createobject('PetStoreAPI')
loAPI.lLogging = .F.
erase (loAPI.cLogFile)

loParameter = createobject('PetParameters')
loParameter.PetName               = 'Weston'
loParameter.Status                = 'available'
loParameter.Category.ID           = 1000
loParameter.Category.CategoryName = 'French Bulldog'
loParameter.AddTag(1000, 'dog')
loParameter.AddTag(1001, 'friendly')
loParameter.PhotoURLS.Add('https://petsRus.com/frenchies/weston.jpg')

llSuccess = loAPI.AddPet(loParameter)
if llSuccess
	messagebox('The pet was added with ID = ' + transform(loAPI.nID))
else
	messagebox(loAPI.cErrorMessage)
endif llSuccess

lnID      = 6
llSuccess = loAPI.GetPet(lnID)
if llSuccess
	messagebox('The pet with ID = ' + transform(lnID) + ' is ' + loAPI.cName + '. Status = ' + loAPI.cStatus)
else
	messagebox(loAPI.cErrorMessage)
endif llSuccess

if loAPI.lLogging
	modify file (loAPI.cLogFile) nowait
endif loAPI.lLogging


* Pet Store test API. See https://petstore.swagger.io/ for documentation.

define class PetStoreAPI as BaseREST of BaseREST.prg

* Override parent properties.

	cURL = 'https://petstore.swagger.io/v2/'

* Custom properties.

	protected cAPIKey
	cAPIKey = 'special-key'
	
	nID     = 0
		&& the pet ID
	cName   = ''
		&& the pet name
	cStatus = ''
		&& the pet's status

* Add a pet to the store.

	function AddPet(toParameter)
		This.AddQueryString('apikey', This.cAPIKey)
		llReturn = This.APICall('POST', '200', 'pet', toParameter)
		if llReturn
			This.nID = This.oResponse.ID
		endif llReturn
		return llReturn
	endfunc

* Find a pet.

	function GetPet(tnPetID)
		This.AddQueryString('apikey', This.cAPIKey)
		llReturn = This.APICall('GET', '200', 'pet/' + transform(tnPetID))
		if llReturn
			This.cName   = This.oResponse.Name
			This.cStatus = This.oResponse.Status
		endif llReturn
		return llReturn
	endfunc

* Handle errors.

	protected function HandleErrors(toJSON)
		if pemstatus(toJSON, 'type', 5) and toJSON.type = 'error'
			This.cErrorMessage = toJSON.message
		endif pemstatus(toJSON, 'type', 5) ...
	endfunc
enddefine

* Parameters object for seasons.

define class PetParameters as BaseParameters of BaseREST.prg
	ID        = 0
	PetName   = ''
		&& the actual parameter is named Name but that wouldn't allow values
		&& that aren't VFP names so we'll call it PetName and rename it
		&& to Name in the JSON
	Status    = ''
	Category  = NULL
	PhotoURLS = NULL
	Tags      = NULL

	function Init
		This.Category  = createobject('Category')
		This.PhotoURLS = createobject('Collection')
		This.Tags      = createobject('Collection')
	endfunc

	function AddTag(tnID, tcName)
		local loTag
		loTag         = createobject('Tag')
		loTag.ID      = tnID
		loTag.TagName = tcName
		This.Tags.Add(loTag)
	endfunc

	function ProcessJSON(tcJSON)
		local lcJSON
		lcJSON = strtran(tcJSON, 'petname',      'name')
		lcJSON = strtran(tcJSON, 'categoryname', 'name')
		lcJSON = strtran(tcJSON, 'tagname',      'name')
		return lcJSON
	endfunc
enddefine

define class Category as Custom
	ID           = 0
	CategoryName = ''
		&& the actual parameter is named Name but that wouldn't allow values
		&& that aren't VFP names so we'll call it CategoryName and rename it
		&& to Name in the JSON
enddefine

define class Tag as Custom
	ID      = 0
	TagName = ''
		&& the actual parameter is named Name but that wouldn't allow values
		&& that aren't VFP names so we'll call it TagName and rename it
		&& to Name in the JSON
enddefine
