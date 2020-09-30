'use strict';

const log = (level, message, details = {}) => console[level](`${message}.\nDetails:\n${JSON.stringify(details)}`);
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
