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
    "name": "proxyStaticFilePaths",
    "displayName": "List of paths of static files which should be served directly from API endpoint, multiple values separated by comma",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "defaultValue": "/js/exponea.min.js,/js/exponea.min.js.map"
  },
  {
    "type": "TEXT",
    "name": "extraValidPaths",
    "displayName": "List of extra valid paths which should be proxyied to API endpoint, multiple values separated by comma",
    "simpleValueType": true,
    "defaultValue": ""
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
const claimRequest = require('claimRequest');
const getCookieValues = require('getCookieValues');
const getRequestBody = require('getRequestBody');
const getRequestHeader = require('getRequestHeader');
const getRequestMethod = require('getRequestMethod');
const getRequestPath = require('getRequestPath');
const getRequestQueryString = require('getRequestQueryString');
const JSON = require('JSON');
const logToConsole = require('logToConsole');
const returnResponse = require('returnResponse');
const setCookie = require('setCookie');
const sendHttpGet = require('sendHttpGet');
const sendHttpRequest = require('sendHttpRequest');
const setResponseBody = require('setResponseBody');
const setResponseHeader = require('setResponseHeader');
const setResponseStatus = require('setResponseStatus');
const getContainerVersion = require('getContainerVersion');
const getRemoteAddress = require('getRemoteAddress');
const getType = require('getType');
const path = getRequestPath();

const cookieWhiteList = ['xnpe_' + data.projectToken, '__exponea_etc__', '__exponea_time2__'];
const headerWhiteList = ['referer', 'user-agent', 'etag'];

log({
    'Name': 'Exponea',
    'Type': 'Processing',
    'data': data,
    'path': path
});

// Check if this Client should proxy static files
if (splitAndSanitize(data.proxyStaticFilePaths).reduce((res,proxyPath)=>res || equalOrStartsOrEnds(path,proxyPath), false)) {
    claimRequest();
    const resultUrl = combineURLs(data.targetAPI, path);
    log({
        'Name': 'Exponea',
        'Type': 'Serving JS',
        'targetAPI': data.targetAPI,
        'path': path,
        'resultUrl': resultUrl
    });
    sendHttpGet(resultUrl, {headers: {'X-Forwarded-For': getRemoteAddress()}}).then((result) => {
      sendProxyResponse(result.body, result.headers, result.statusCode);
    });
    return;
}

const validPaths = [
  '/bulk',
  '/managed-tags/show',
  '/campaigns/banners/show',
  '/campaigns/experiments/show',
  '/campaigns/html/get',
  '/optimization/recommend/user',
  '/webxp/projects/',
  '/webxp/data/modifications/',
  '/webxp/bandits/reward',
  '/webxp/script-async/',
  '/webxp/script/'
];

let isValidPath = false; 

// Check if this Client should claim request
if (validPaths.reduce((res,validPath)=>res || equalOrStartsOrEnds(path,validPath,true), false)) {
    log({
        'Name': 'Exponea',
        'Type': 'Valid path',
        'path': path
    });
    isValidPath = true;
}


if (!isValidPath) {
  return;
} else {

    claimRequest();

    const traceId = getRequestHeader('trace-id');
    const requestOrigin = getRequestHeader('Origin');
    const requestMethod = getRequestMethod();
    const requestBody = getRequestBody();
    const requestUrl = generateRequestUrl();
    const requestHeaders = generateRequestHeaders();

    log({
        'Name': 'Exponea',
        'Type': 'Request',
        'TraceId': traceId,
        'RequestOrigin': requestOrigin,
        'RequestMethod': requestMethod,
        'RequestUrl': requestUrl,
        'RequestHeaders': requestHeaders,
        'RequestBody': requestBody,
    });
    sendHttpRequest(requestUrl, {method: requestMethod, headers: requestHeaders}, requestBody).then((result) => {
        log({
        'Name': 'Exponea',
        'Type': 'Response',
        'TraceId': traceId,
        'ResponseStatusCode': result.statusCode,
        'ResponseHeaders': result.headers,
        'ResponseBody': result.body,
        });

        for (const key in result.headers) {
            if (key === 'set-cookie') {
                setResponseCookies(result.headers[key]);
            } else {
                setResponseHeader(key, result.headers[key]);
            }
        }

        setResponseBody(result.body||"");
        setResponseStatus(result.statusCode);

        if (requestOrigin) {
            setResponseHeader('access-control-allow-origin', requestOrigin);
            setResponseHeader('access-control-allow-credentials', 'true');
        }

        returnResponse();
    });
}


function generateRequestUrl() {
    let url = combineURLs(data.targetAPI, getRequestPath());
    const queryParams = getRequestQueryString();

    if (queryParams) url = url + '?' + queryParams;

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

    headers.cookie = '';

    for (let i = 0; i < cookieWhiteList.length; i++) {
        let cookieName = cookieWhiteList[i];
        let cookieValue = getCookieValues(cookieName);

        if (cookieValue && cookieValue.length) {
            cookies.push(cookieName + '=' + cookieValue[0]);
        }
    }

    headers.cookie = cookies.join('; ');
    headers['X-Forwarded-For'] = getRemoteAddress();

    return headers;
}

function setResponseCookies(setCookieHeader) {
    for (let i = 0; i < setCookieHeader.length; i++) {
        let setCookieArray = setCookieHeader[i].split('; ').map(pair => pair.split('='));
        let setCookieJson = '';

        for (let j = 1; j < setCookieArray.length; j++) {
            if (j === 1) setCookieJson += '{';
            if (setCookieArray[j].length > 1) setCookieJson += '"' + setCookieArray[j][0] + '": "' + setCookieArray[j][1] + '"'; else setCookieJson += '"' + setCookieArray[j][0] + '": ' + true;
            if (j + 1 < setCookieArray.length) setCookieJson += ','; else setCookieJson += '}';
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
    if (!data.logType) {
        return isDebug;
    }

    if (data.logType === 'no') {
        return false;
    }

    if (data.logType === 'debug') {
        return isDebug;
    }

    return data.logType === 'always';
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
    return lastIndex > -1 && (string.length === (lastIndex + substring.length));
}


function equalOrStartsOrEnds(string, substring, withWildcard) {
    if (substring.length === 0) return false;
    
    const containWildcard = substring.indexOf("*") > -1;
    const eq = string === substring;
    if (eq) return true;
    log({
        'Name': 'Exponea',
        'Type': 'EqualOrStartsOrEnds',
        'string': string,
        'substring': substring,
        'withWildcard': withWildcard,
        'containWildcard': containWildcard
    });
    if (!withWildcard || !containWildcard) {
        return startsWith(string, substring) || endsWith(string, substring);
    } else {
        const parsedSubstring = withWildcard ? substring.split("*", 2) : [substring];
        return startsWith(string, parsedSubstring[0]) && endsWith(string, parsedSubstring[1]); 
    }
}

function splitAndSanitize(arr) {
    if (getType(arr) !== 'string') return [];
    return arr.split(',').map(a=>a.trim()).filter(a=>a);
}

function removeEndSlash(string) {
    if (endsWith(string, '/')) return string.slice(0,-1);
    return string;
}
function removeStartSlash(string) {
    if (startsWith(string, '/')) return string.slice(1);
    return string;
}

function combineURLs(baseURL, relativeURL) {
    return (
        relativeURL ?
            removeEndSlash(baseURL) + '/' + removeStartSlash(relativeURL) :
            baseURL
    );
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


