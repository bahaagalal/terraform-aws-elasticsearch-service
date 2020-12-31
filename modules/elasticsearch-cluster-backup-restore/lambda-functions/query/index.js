'use strict';

const AWS = require('aws-sdk');

const { debug } = require('./Logger');
const { request } = require('./SignedRequest');

exports.handler = async event => {
  const bucketId = process.env.BUCKET_ID;
  const bucketRegion = process.env.BUCKET_REGION;
  const elasticsearchDomainEndpoint = process.env.ELASTICSEARCH_DOMAIN_ENDPOINT;
  const elasticsearchDomainIAMRoleARN = process.env.ELASTICSEARCH_DOMAIN_IAM_ROLE_ARN;

  const req = request(
    bucketRegion,
    new AWS.Endpoint(elasticsearchDomainEndpoint),
    new AWS.EnvironmentCredentials('AWS'),
  );

  const repositorySettings = { bucket: bucketId, region: bucketRegion, role_arn: elasticsearchDomainIAMRoleARN };
  await req('PUT', `/_snapshot/${bucketId}`, { type: 's3', settings: repositorySettings });

  const snapshot = event.snapshot ? event.snapshot : '_all';
  const snapshotResponse = await req('GET', `/_snapshot/${bucketId}/${snapshot}`);
  debug('snapshots', JSON.stringify(snapshotResponse, null, 2));
};
