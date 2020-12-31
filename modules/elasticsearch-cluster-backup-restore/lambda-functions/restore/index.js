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

  const snapshotSettings = {
    indices: event.indices || '*',
    ignore_unavailable: false,
    include_aliases: (event.include_aliases !== undefined && event.include_aliases !== null) ? event.include_aliases : false,
    include_global_state: (event.include_global_state !== undefined && event.include_global_state !== null) ? event.include_global_state : false
  };
  const snapshot = event.snapshot;
  const snapshotResponse = await req('POST', `/_snapshot/${bucketId}/${snapshot}/_restore`, snapshotSettings);
  debug('restore acknowledged', JSON.stringify(snapshotResponse, null, 2));
};
