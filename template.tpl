﻿___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "CLIENT",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Exponea Analytics Client",
  "brand": {
    "id": "brand_dummy",
    "displayName": "",
    "thumbnail": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAOEAAADhCAMAAAAJbSJIAAAAM1BMVEX/zQAcFzP/0gAAADSohyH/1gClhCL/zwAAADehgSPWrBWwjSD/2wAPDTSsiiD/3wBxWyvoA5xkAAABPUlEQVR4nO3cW26DMBRF0WAgDSWPzn+0/bdV0JUq2TdZawTeUfIBB3K5AAAAAAAAAAAAAAAAAAAAwLjWqNL7xEHrbY65bckS13mKmReFg1GocHwKFY5PocLxKVQ4vqbwcXb5dE1e+Ph5Loeu31+9zxxTF87PtRxLFtgWZvuZnVKYn8L8FOanMD+F+SnM7/0KS7V3vurC/Z57IS1bvYhOlewLaVmi92WaT2Dwr7FChQr7U6hQYX8KFSrs7xMLg4+XDr+QNoXzfjyIpltI28L7ySCabSFtC9feR/pnCvNTmJ/C/BTmpzA/hfm9YWE1b973uvCV/B3S9hXRqRK9xB9tIQ0/qH5qtPs0ChUq7E+hQoX9KVSosL8PKIz+wc65wRbSsgUH0HwLaXT/TL+QAgAAAAAAAAAAAAAAAAAA/O0Xm1MdrfEGnRgAAAAASUVORK5CYII\u003d"
  },
  "description": "Exponea helps you maximize profits and drive customer loyalty by targeting the right customers with the right message at the perfect time.",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "projectToken",
    "displayName": "Project token",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "targetAPI",
    "displayName": "API endpoint",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "proxyJsFilePath",
    "displayName": "A path that will be used for the exponea.js serving",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "defaultValue": "/js/exponea.min.js"
  },
  {
    "type": "GROUP",
    "name": "logsGroup",
    "displayName": "Logs Settings",
    "groupStyle": "ZIPPY_CLOSED",
    "subParams": [
      {
        "type": "RADIO",
        "name": "logType",
        "radioItems": [
          {
            "value": "no",
            "displayValue": "Do not log"
          },
          {
            "value": "debug",
            "displayValue": "Log to console during debug and preview"
          },
          {
            "value": "always",
            "displayValue": "Always log to console"
          }
        ],
        "simpleValueType": true,
        "defaultValue": "debug"
      }
    ]
  }
]


___SANDBOXED_JS_FOR_SERVER___

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

___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "all"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_request",
        "versionId": "1"
      },
      "param": [
        {
          "key": "requestAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "headerAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "queryParameterAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "return_response",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_response",
        "versionId": "1"
      },
      "param": [
        {
          "key": "writeResponseAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "writeHeaderAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "send_http",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "set_cookies",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedCookies",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "name"
                  },
                  {
                    "type": 1,
                    "string": "domain"
                  },
                  {
                    "type": 1,
                    "string": "path"
                  },
                  {
                    "type": 1,
                    "string": "secure"
                  },
                  {
                    "type": 1,
                    "string": "session"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "any"
                  },
                  {
                    "type": 1,
                    "string": "any"
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "get_cookies",
        "versionId": "1"
      },
      "param": [
        {
          "key": "cookieAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_container_data",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_template_storage",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  }
]


___TESTS___

scenarios: []


___NOTES___

Created on 24. 8. 2021, 13:27:38


