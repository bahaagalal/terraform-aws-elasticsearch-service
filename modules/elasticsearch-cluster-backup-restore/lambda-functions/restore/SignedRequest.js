'use strict';

const AWS = require('aws-sdk');

const request = (region, endpoint, credentials) => (method, path, body) => {
  const httpRequest = new AWS.HttpRequest(endpoint);

  httpRequest.region = region;
  httpRequest.method = method;
  httpRequest.path = path;
  httpRequest.headers['presigned-expires'] = false;
  httpRequest.headers['Host'] = endpoint.host;
  httpRequest.headers['Accept'] = 'application/json';
  httpRequest.headers['Accept-Charset'] = 'utf-8';
  httpRequest.headers['Content-Type'] = 'application/json; charset=utf-8';

  if (body) httpRequest.body = JSON.stringify(body);

  const signer = new AWS.Signers.V4(httpRequest, 'es');
  signer.addAuthorization(credentials, new Date());

  const httpClient = new AWS.NodeHttpClient();

  return new Promise((resolve, reject) => {
    httpClient.handleRequest(httpRequest, null, httpResponse => {
      let responseBody = '';
      httpResponse.on('data', chunk => responseBody += chunk);
      httpResponse.on('end', () => {
        const response = JSON.parse(responseBody);
        const err = response.error || response.errors || response.Message;
        if (err) {
          reject(new Error(responseBody));
        } else {
          resolve(response);
        }
      });
    }, reject);
  });
};

module.exports = {
  request,
};
