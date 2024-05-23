const claimRequest = require("claimRequest");
const getCookieValues = require("getCookieValues");
const getRequestBody = require("getRequestBody");
const getRequestHeader = require("getRequestHeader");
const getRequestMethod = require("getRequestMethod");
const getRequestPath = require("getRequestPath");
const getRequestQueryString = require("getRequestQueryString");
const JSON = require("JSON");
const logToConsole = require("logToConsole");
const returnResponse = require("returnResponse");
const setCookie = require("setCookie");
const templateDataStorage = require("templateDataStorage");
const sendHttpGet = require("sendHttpGet");
const getTimestampMillis = require("getTimestampMillis");
const sendHttpRequest = require("sendHttpRequest");
const setResponseBody = require("setResponseBody");
const setResponseHeader = require("setResponseHeader");
const setResponseStatus = require("setResponseStatus");
const getContainerVersion = require("getContainerVersion");
const getRemoteAddress = require("getRemoteAddress");
const path = getRequestPath();
const getType = require("getType");
const Object = require("Object");

// Check if this Client should serve exponea.js file
if (path === data.proxyJsFilePath) {
	claimRequest();

	const now = getTimestampMillis();
	const thirty_minutes_ago = now - 30 * 60 * 1000;

	// save js sdk to server cache if it's not been done yet
	if (templateDataStorage.getItemCopy("exponea_js") == null || templateDataStorage.getItemCopy("exponea_stored_at") < thirty_minutes_ago) {
		sendHttpGet(data.targetAPI + "/js/exponea.min.js", { headers: { "X-Forwarded-For": getRemoteAddress() } }).then((result) => {
			if (result.statusCode === 200) {
				templateDataStorage.setItemCopy("exponea_js", result.body);
				templateDataStorage.setItemCopy("exponea_headers", result.headers);
				templateDataStorage.setItemCopy("exponea_stored_at", now);
			}
			sendProxyResponse(result.body, result.headers, result.statusCode);
		});
	} else {
		sendProxyResponse(templateDataStorage.getItemCopy("exponea_js"), templateDataStorage.getItemCopy("exponea_headers"), 200);
	}
}

// Check if this Client should serve exponea.js.map file (Just only to avoid annoying error in console)
if (path === "/exponea.min.js.map") {
	sendProxyResponse('{"version": 1, "mappings": "", "sources": [], "names": [], "file": ""}', { "Content-Type": "application/json" }, 200);
}

const cookieWhiteList = ["xnpe_" + data.projectToken, "__exponea_etc__", "__exponea_time2__"];
const headerWhiteList = ["referer", "user-agent", "etag", "Access-Control-Request-Headers"];

const validPaths = [
	"/bulk",
	"/managed-tags/show",
	"/campaigns/banners/show",
	"/campaigns/experiments/show",
	"/campaigns/html/get",
	"/optimization/recommend/user",
	"/webxp/projects/",
	"/webxp/data/modifications/",
	"/webxp/bandits/reward",
	"/webxp/script-async/",
	"/webxp/script/",
	"/editor",
];

let isValidPath = false;

// Check if this Client should claim request
if (validPaths.reduce((res, validPath) => res || equalOrStartsOrEnds(path, validPath, true), false)) {
	log({
		Name: "Exponea",
		Type: "Valid path",
		path: path,
	});
	isValidPath = true;
}

if (!isValidPath) {
	return;
} else {
	claimRequest();

	const traceId = getRequestHeader("trace-id");
	const requestOrigin = getRequestHeader("Origin");
	const requestMethod = getRequestMethod();
	const requestBody = getRequestBody();
	const requestUrl = generateRequestUrl();
	const requestHeaders = generateRequestHeaders();

	log({
		Name: "Exponea",
		Type: "Request",
		TraceId: traceId,
		RequestOrigin: requestOrigin,
		RequestMethod: requestMethod,
		RequestUrl: requestUrl,
		RequestHeaders: requestHeaders,
		RequestBody: requestBody,
	});
	const response = sendHttpRequest(requestUrl, { method: requestMethod, headers: requestHeaders }, requestBody);

	response
		.then((result) => {
			log({
				Name: "Exponea",
				Type: "Received Response",
				TraceId: traceId,
				ResponseStatusCode: result.statusCode,
				ResponseHeaders: result.headers,
				ResponseBody: result.body,
			});

			// if transfer-encoding header is present in the response, remove it to avoid problems as it's a hop-by-hop header
           		Object.delete(result.headers, "transfer-encoding");

			for (const key in result.headers) {
				if (key === "set-cookie") {
					setResponseCookies(result.headers[key]);
				} else {
					setResponseHeader(key, result.headers[key]);
				}
			}

			// Access-Control-Request-Headers header is now sent with the modifications data request, which will fail unless Access-Control-Request-Headers is set
			if (requestHeaders["Access-Control-Request-Headers"]) {
				setResponseHeader("Access-Control-Allow-Headers", requestHeaders["Access-Control-Request-Headers"]);
			}

			setResponseBody(result.body || "");

			setResponseStatus(result.statusCode);
			
			if (requestOrigin) {
				setResponseHeader("access-control-allow-origin", requestOrigin);
				setResponseHeader("access-control-allow-credentials", "true");
			}

			log({
				Name: "Exponea",
				Type: "Updated Response",
				TraceId: traceId,
				ResponseStatusCode: result.statusCode,
				ResponseHeaders: result.headers,
				ResponseBody: result.body,
			});

			returnResponse();
		})
		.catch((rejectedValue) => {
			log({
				Type: "Promise was rejected",
				Message: rejectedValue,
			});
		});
}

function generateRequestUrl() {
	let url = combineURLs(data.targetAPI, getRequestPath());
	const queryParams = getRequestQueryString();

	if (queryParams) url = url + "?" + queryParams;

	return url;
}

function generateRequestHeaders() {
	let headers = {};
	let cookies = [];

	for (let i = 0; i < headerWhiteList.length; i++) {
		let headerName = headerWhiteList[i];
		let headerValue = getRequestHeader(headerName);

		if (headerValue) {
			headers[headerName] = getRequestHeader(headerName);
		}
	}

	headers.cookie = "";

	for (let i = 0; i < cookieWhiteList.length; i++) {
		let cookieName = cookieWhiteList[i];
		let cookieValue = getCookieValues(cookieName);

		if (cookieValue && cookieValue.length) {
			cookies.push(cookieName + "=" + cookieValue[0]);
		}
	}

	headers.cookie = cookies.join("; ");
	headers["X-Forwarded-For"] = getRemoteAddress();

	return headers;
}

function setResponseCookies(setCookieHeader) {
	for (let i = 0; i < setCookieHeader.length; i++) {
		let setCookieArray = setCookieHeader[i].split("; ").map((pair) => pair.split("="));
		let setCookieJson = "";

		for (let j = 1; j < setCookieArray.length; j++) {
			if (j === 1) setCookieJson += "{";
			if (setCookieArray[j].length > 1) setCookieJson += '"' + setCookieArray[j][0] + '": "' + setCookieArray[j][1] + '"';
			else setCookieJson += '"' + setCookieArray[j][0] + '": ' + true;
			if (j + 1 < setCookieArray.length) setCookieJson += ",";
			else setCookieJson += "}";
		}

		setCookie(setCookieArray[0][0], setCookieArray[0][1], JSON.parse(setCookieJson));
	}
}

function sendProxyResponse(response, headers, statusCode) {
	setResponseStatus(statusCode);
	setResponseBody(response);

	for (const key in headers) {
		setResponseHeader(key, headers[key]);
	}

	returnResponse();
}

function determinateIsLoggingEnabled() {
	const containerVersion = getContainerVersion();
	const isDebug = containerVersion.debugMode;

	if (path !== "/campaigns/banners/show") {
		return false;
	}

	if (!data.logType) {
		return isDebug;
	}

	if (data.logType === "no") {
		return false;
	}

	if (data.logType === "debug") {
		return isDebug;
	}

	return data.logType === "always";
}

function log(data) {
	const isLoggingEnabled = determinateIsLoggingEnabled();
	if (isLoggingEnabled) {
		logToConsole(JSON.stringify(data));
	}
}

function startsWith(string, substring) {
	return string.indexOf(substring) === 0;
}

function endsWith(string, substring) {
	const lastIndex = string.lastIndexOf(substring);
	return lastIndex > -1 && string.length === lastIndex + substring.length;
}

function equalOrStartsOrEnds(string, substring, withWildcard) {
	if (substring.length === 0) return false;

	const containWildcard = substring.indexOf("*") > -1;
	const eq = string === substring;
	if (eq) return true;
	if (!withWildcard || !containWildcard) {
		return startsWith(string, substring) || endsWith(string, substring);
	} else {
		const parsedSubstring = withWildcard ? substring.split("*", 2) : [substring];
		return startsWith(string, parsedSubstring[0]) && endsWith(string, parsedSubstring[1]);
	}
}

function splitAndSanitize(arr) {
	if (getType(arr) !== "string") return [];
	return arr
		.split(",")
		.map((a) => a.trim())
		.filter((a) => a);
}

function removeEndSlash(string) {
	if (endsWith(string, "/")) return string.slice(0, -1);
	return string;
}
function removeStartSlash(string) {
	if (startsWith(string, "/")) return string.slice(1);
	return string;
}

function combineURLs(baseURL, relativeURL) {
	return relativeURL ? removeEndSlash(baseURL) + "/" + removeStartSlash(relativeURL) : baseURL;
}
