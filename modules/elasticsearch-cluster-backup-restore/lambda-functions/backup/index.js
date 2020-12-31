'use strict';

const AWS = require('aws-sdk');

const { debug, error } = require('./Logger');
const { request } = require('./SignedRequest');
const { slack } = require('./Notification');

const getTime = () => {
  const now = new Date();
  const year = new Intl.DateTimeFormat('en', { year: 'numeric' }).format(now);
  const month = new Intl.DateTimeFormat('en', { month: 'short' }).format(now);
  const day = new Intl.DateTimeFormat('en', { day: '2-digit' }).format(now);
  const hour = new Intl.DateTimeFormat('en', { hour: '2-digit' }).format(now).replace(' ', '-');
  const minute = new Intl.DateTimeFormat('en', { minute: '2-digit' }).format(now);
  return `${year}-${month}-${day}-${hour}-${minute}`.toLowerCase();
};

const wait = seconds => new Promise(resolve => setTimeout(resolve, seconds * 1000));

const waitSnapshotToFinish = async(req, bucketId, snapshot, waitTimeInSeconds) => {
  const response = await req('GET', `/_snapshot/${bucketId}/${snapshot}/_status`);
  const snapshotResponse = response.snapshots[0];
  const status = snapshotResponse.state;

  debug('status', JSON.stringify(snapshotResponse, null, 2));

  if (status === "STARTED") {
    await wait(waitTimeInSeconds);
    return await waitSnapshotToFinish(req, bucketId, snapshot, waitTimeInSeconds);
  } else if (status === "SUCCESS") {
    return snapshotResponse;
  } else {
    throw new Error(snapshotResponse);
  }
};

exports.handler = async event => {
  const bucketId = process.env.BUCKET_ID;
  const bucketRegion = process.env.BUCKET_REGION;
  const elasticsearchDomainEndpoint = process.env.ELASTICSEARCH_DOMAIN_ENDPOINT;
  const elasticsearchDomainIAMRoleARN = process.env.ELASTICSEARCH_DOMAIN_IAM_ROLE_ARN;
  const slackWebhookURL = process.env.SLACK_WEBHOOK_URL;

  const req = request(
    bucketRegion,
    new AWS.Endpoint(elasticsearchDomainEndpoint),
    new AWS.EnvironmentCredentials('AWS'),
  );

  const repositorySettings = { bucket: bucketId, region: bucketRegion, role_arn: elasticsearchDomainIAMRoleARN };
  await req('PUT', `/_snapshot/${bucketId}`, { type: 's3', settings: repositorySettings });

  const snapshot = getTime();
  const snapshotSettings = {
    indices: event.indices || '*',
    ignore_unavailable: false,
    include_global_state: (event.include_global_state !== undefined && event.include_global_state !== null) ? event.include_global_state : true
  };

  try {
    await req('PUT', `/_snapshot/${bucketId}/${snapshot}`, snapshotSettings);
    debug(`backup operation is in progress (snapshot: ${snapshot}).`);
    await waitSnapshotToFinish(req, bucketId, snapshot, 10);
    debug(`backup operation is complete (snapshot: ${snapshot}).`);
    await slack(slackWebhookURL, {
      success: true,
      message: `${elasticsearchDomainEndpoint} backup finished`,
      details: `_(Snapshot: ${snapshot})_`,
    }).catch(() => null);
  } catch(err) {
    error(`backup operation failed.`, err.toString());
    await slack(slackWebhookURL, {
      success: false,
      message: `${elasticsearchDomainEndpoint} backup failed`,
      details: err.toString(),
    }).catch(() => null);
  }
};
