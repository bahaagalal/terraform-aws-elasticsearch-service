'use strict';

const log = (level, message, details = {}) => {
    let logMessage = message;
    if(details.constructor === Object && Object.keys(details).length > 0) {
        logMessage += `\nDetails:\n${JSON.stringify(details, null, 2)}`;
    }

    console[level](logMessage);
};
const debug = (message, details) => log('debug', message, details);
const info = (message, details) => log('info', message, details);
const warn = (message, details) => log('warn', message, details);
const error = (message, details) => log('error', message, details);

module.exports = {
    debug,
    info,
    warn,
    error,
};
