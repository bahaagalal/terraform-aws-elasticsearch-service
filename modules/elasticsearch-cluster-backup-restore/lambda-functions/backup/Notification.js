'use strict';

const url = require('url');
const https = require('https');
const util = require('util');

const slack = (webhookURL, notification) => {
  const slackWebhookURL = url.parse(webhookURL);
  const { success, message, details } = notification;

  const body = {
    text: `${success? ':white_check_mark:' : ':x:'} ${message}`,
    blocks: [
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `*${success? ':white_check_mark:' : ':x:'} ${message}*`,
        },
      },
      {
        type: 'context',
        elements: [
          {
            type: 'mrkdwn',
            text: details,
          },
        ],
      },
    ],
  };

  return new Promise((resolve, reject) => {
    const httpRequest = https.request({
      hostname: slackWebhookURL.hostname,
      path: slackWebhookURL.pathname,
      method: 'POST'
    }, response => {
      response.setEncoding('utf8');
      response.on('data', data => resolve(data));
    });

    httpRequest.on('error', error => reject(error));
    httpRequest.write(util.format('%j', body));
    httpRequest.end();
  });
};

module.exports = {
  slack,
};
