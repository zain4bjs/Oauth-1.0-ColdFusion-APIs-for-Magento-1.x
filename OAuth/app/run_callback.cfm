<!-- REPLACE FOLLOWING WITH YOUR MAGENTO CONSUMER INFO
 ***CONSUMER KEY = CONSUMER_KEY
 ***CONSUMER SECRET = CONSUMER_SECRET
 ***MAGENTO HOSTNAME = MAGENTO_HOSTNAME
-->
<cfsilent>
	<cfset CONSUMER_KEY = "">
	<cfset CONSUMER_SECRET = "">
	<cfset MAGENTO_HOSTNAME = "https://www.magento.com">
	<cfset requestToken = MAGENTO_HOSTNAME & "/oauth/token">
</cfsilent>

<!---Verify we have the token object in the user's session--->
<cfif not StructKeyExists(session, "token")>
	<p>There was an error. Token object not found in session scope.</p>
	<cfabort>
</cfif>

<!---Verify that the oauth_token url parameter was passed back to the callback--->
<cfif not StructKeyExists(url, "oauth_token") OR (StructKeyExists(url, "oauth_token") AND not Len(url.oauth_token))>
	<p>There was an error. Authentication token not returned.</p>
	<cfabort>
</cfif>

<!---Verify that the token we have and the token provided are the same--->
<cfif session.token.getKey() neq url.oauth_token>
	<p>There was an error. Authentication token and session token do not match.</p>
	<cfabort>
</cfif>

<!---Verify that the oauth_verifier parameter was passed back to the callback--->
<cfif not StructKeyExists(url, "oauth_verifier") OR (StructKeyExists(url, "oauth_verifier") AND not Len(url.oauth_verifier))>
	<p>There was an error. Authentication verifier not returned.</p>
	<cfabort>
</cfif>

<!---Perform three-step oAuth authentication to retreive the access token--->
<cfset oAuthRequest = new includes.oauth.Request()>
<cfset oAuthConsumer = new includes.oauth.Consumer()>

<!---setup consumer--->
<cfset oauthConsumer.setSecret(CONSUMER_SECRET)>
<cfset oauthConsumer.setKey(CONSUMER_KEY)>

<!---setup request--->
<cfset oAuthRequest.setMethod("POST")>
<cfset oAuthRequest.setUrl(requestToken)>
<cfset oAuthRequest.setConsumer(oAuthConsumer)>
<cfset oAuthRequest.setToken(session.token)>

<!---Add oauth_verifier parameter to the request--->
<cfset oAuthRequest.addParameter(key="oauth_verifier", value=url.oauth_verifier)>

<!---use HMAC-SHA1 signature method--->
<cfset signatureMethod = new includes.oauth.methods.HmacSha1SignatureMethod()>

<!---sign request--->
<cfset oAuthRequest.signWithSignatureMethod(signatureMethod=signatureMethod)>

<!---POST using request URL--->
<cfset httpRequest = new Http()>
<cfset httpRequest.setUrl(oAuthRequest.getUrl())>
<cfset httpRequest.setMethod(oAuthRequest.getMethod())>
<cfset httpRequest.addParam(type="header", name="Authorization", value=oAuthRequest.toHeader())>
<cfset httpRequest.addParam(type="header", name="Content-Type", value="application/x-www-form-urlencoded")>
<cfset httpRequest.addParam(type="body", value="oauth_verifier=#url.oauth_verifier#")>
<cfset httpRequest.setCharset("utf-8")>
<cfset httpResult = httpRequest.send().getPrefix()>

<cfdump var="#httpResult#">
<!---Verify status code--->
<cfif httpResult.responseHeader.status_code neq 200>
	<p>There was an error. The status code indicates that there was an error obtaining the request token.</p>
	<cfabort>
</cfif>

<!---Verify result--->
<cfif not Len(httpResult.fileContent)>
	<p>There was an error. No response content was returned.</p>
	<cfabort>
</cfif>

<!---parse result--->
<cfset parameters = {}>
<cfset pairs = ListToArray(httpResult.fileContent, "&")>
<cfloop array="#pairs#" index="pair">
	<cfset key = ListGetAt(pair, 1, "=")>
	<cfset value = ListGetAt(pair, 2, "=")>
	<cfset parameters[key] = value>
</cfloop>

<!---Verify oauth_token--->
<cfif not StructKeyExists(parameters, "oauth_token")>
	<p>There was an error. Token key was not returned.</p>
	<cfabort>
</cfif>

<!---Verify oauth_token_secret--->
<cfif not StructKeyExists(parameters, "oauth_token_secret")>
	<p>There was an error. Token secret was not returned.</p>
	<cfabort>
</cfif>

<!---Store access token key and secret--->
<cfset session.token.setKey(parameters.oauth_token)>
<cfset session.token.setSecret(parameters.oauth_token_secret)>