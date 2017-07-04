component {
	
	this.name = "BJS Soft Solution";
	this.applicationTimeout = createTimespan(1,	0, 0, 0);
	this.sessionManagement = true;
	this.sessionTimeout = createTimespan(0, 1, 0, 0);
	this.clientStorage = "cookie";
	this.timeout = 60;
	
	this.mappings["/includes"] = getDirectoryFromPath(getCurrentTemplatePath()) & "includes/";
	this.mappings['/net'] = getDirectoryFromPath(getCurrentTemplatePath()) & "net/";
	

	/**
	* @hint The application has started.
	*/
	public boolean function onApplicationStart() {
		return true;
	}
	
	/**
	* @hint The start of a request.
	*/
	public boolean function onRequestStart(required string page) {
		return true;
	}
	
	// /**
	// * @hint Uncaught exception handler.
	// */
	// public void function onError(required any exception, string eventName="") {
	// 	try {
	// 		writeDump("Uncaught Exception.  #arguments.exception# #arguments.exception.detail#");
	// 	}
	// 	catch (any e) {
	// 		writeDump(e);
	// 		abort;
	// 		throw("Error invoking application error handler. #e.message# #e.detail#");
	// 	}
	// }
	
	// /**
	// * @hint Initialize wirebox and creates application.wirebox injector.
	// */
	
}