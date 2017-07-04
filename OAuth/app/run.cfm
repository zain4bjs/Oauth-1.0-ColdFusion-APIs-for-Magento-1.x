<!-- REPLACE FOLLOWING WITH YOUR MAGENTO CONSUMER INFO
 ***CONSUMER KEY = CONSUMER_KEY
 ***CONSUMER SECRET = CONSUMER_SECRET
 ***MAGENTO HOSTNAME = MAGENTO_HOSTNAME
 ***YOUR SERVER HOSTNAME = SERVER_CALLBACK // Change http://www.myserver.com - YOUR SERVER DOMAIN ONLY
 ***YOUR MAGENTO ADMIN URL = MAGENTO_ADMIN_URL Change // https://www.magento.com/index.php/admin - YOUR SERVER DOMAIN URL
-->
<cfsilent>
	<cfset CONSUMER_KEY = "">
	<cfset CONSUMER_SECRET = "">
	<cfset MAGENTO_HOSTNAME = "https://www.magento.com">
	<cfset SERVER_CALLBACK = "http://www.myserver.com/app/run_callback.cfm">
	<cfser MAGENTO_ADMIN_URL = "https://www.magento.com/index.php/admin">
	<cfset initiateAuth = MAGENTO_HOSTNAME & "/oauth/initiate">
</cfsilent>

<cfset oAuthRequest = new includes.oauth.Request()>
<cfset oAuthConsumer = new includes.oauth.Consumer()>
<cfset oAuthToken = new includes.oauth.Token()>

<!---setup consumer--->
<cfset oauthConsumer.setSecret(CONSUMER_SECRET)>
<cfset oauthConsumer.setKey(CONSUMER_KEY)>

<!---setup request--->
<cfset oAuthRequest.setMethod("POST")>
<cfset oAuthRequest.setUrl(initiateAuth)>
<cfset oAuthRequest.setCallback(CALLBACK)>
<cfset oAuthRequest.setConsumer(oAuthConsumer)>
<cfset oAuthRequest.setToken(oAuthToken)>

<!---use HMAC-SHA1 signature method--->
<cfset signatureMethod = new includes.oauth.methods.HmacSha1SignatureMethod()>

<!---sign request--->
<cfset oAuthRequest.signWithSignatureMethod(signatureMethod=signatureMethod)>

<!---POST using request URL--->
<cfset httpRequest = new Http()>
<cfset httpRequest.setUrl(oAuthRequest.getUrl())>
<cfset httpRequest.setMethod(oAuthRequest.getMethod())>
<cfset httpRequest.addParam(type="header", name="Authorization", value=oAuthRequest.toHeader())>
<cfset httpRequest.setCharset("utf-8")>

<cfset httpResult = httpRequest.send().getPrefix()>

<!---Verify status code--->
<cfif httpResult.Responseheader.status_code neq 200>
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
	<p>There was an error. Token was not returned.</p>
	<cfabort>
</cfif>

<!---Verify callback_confirmed--->
<cfif not StructKeyExists(parameters, "oauth_callback_confirmed") OR (StructKeyExists(parameters, "oauth_callback_confirmed") AND not IsBoolean(parameters.oauth_callback_confirmed)) OR (StructKeyExists(parameters, "oauth_callback_confirmed") AND IsBoolean(parameters.oauth_callback_confirmed) AND not parameters.oauth_callback_confirmed)>
	<p>There was an error. The callback was not confirmed.</p>
	<cfabort>
</cfif>

<!---Store request token key and secret--->
<cfset oAuthToken.setKey(parameters.oauth_token)>
<cfif StructKeyExists(parameters, "oauth_token_secret")>
	<cfset oAuthToken.setSecret(parameters.oauth_token_secret)>
</cfif>

<!---Store Token instance for the user's session--->
<cfset session.token = oAuthToken>

<!---Redirect user to authenticate with Magento--->
<cflocation url="#MAGENTO_ADMIN_URL#/oauth_authorize?oauth_token=#parameters.oauth_token#" statuscode="302" addtoken="false">