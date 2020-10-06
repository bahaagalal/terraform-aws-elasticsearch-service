'use strict';

const AWS = require('aws-sdk');

const { debug, error } = require('./logger');

exports.handler = async event => {
    debug('Event', event);

    const region = process.env.REGION;
    const bucket = process.env.BUCKET;
    const role = process.env.ROLE;

    const req = request(
        region,
        new AWS.Endpoint(process.env.ELASTICSEARCH_DOMAIN_ENDPOINT),
        new AWS.EnvironmentCredentials('AWS'),
    );

    const repositorySettings = { bucket, region, role_arn: role };
    debug('START: Ensuring S3 Repository', repositorySettings);
    const repositoryResponse = await req('PUT', `/_snapshot/${bucket}`, { type: 's3', settings: repositorySettings });
    debug('SUCCESS: Ensuring S3 Repository', repositoryResponse);

    const snapshot = event.snapshot? event.snapshot : '_all';
    debug(`START: List Snapshots (${snapshot})`);
    const snapshotResponse = await req('GET', `/_snapshot/${bucket}/${snapshot}`);
    debug(`SUCCESS: List Snapshots (${snapshot})`, snapshotResponse);
};

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
    if(body) httpRequest.body = JSON.stringify(body);

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
                if(err) {
                    error('Response Error', err);
                    reject(new Error(responseBody));
                } else {
                    resolve(response);
                }
            });
        }, reject);
    });
};
