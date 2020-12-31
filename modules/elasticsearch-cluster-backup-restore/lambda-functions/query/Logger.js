'use strict';

/**
 * print log line to stdout.
 * @param {string} level The log level, can be DEBUG, INFO, WARN, or ERROR.
 * @param {string} message The log message.
 * @param {string} details The log details.
 */
const log = (level, message, details = "") => console.log(`${level}: ${message}${details? `\n${details}` : ''}`);

/**
 * shorthand function to print DEBUG log messages
 * @param {string} message The log message.
 * @param {string} details The log details.
 */
const debug = (message, details) => log('DEBUG', message, details);

/**
 * shorthand function to print INFO log messages
 * @param {string} message The log message.
 * @param {string} details The log details.
 */
const info = (message, details) => log('INFO', message, details);

/**
 * shorthand function to print WARN log messages
 * @param {string} message The log message.
 * @param {string} details The log details.
 */
const warn = (message, details) => log('WARN', message, details);

/**
 * shorthand function to print ERROR log messages
 * @param {string} message The log message.
 * @param {string} details The log details.
 */
const error = (message, details) => log('ERROR', message, details);

module.exports = {
  debug,
  info,
  warn,
  error,
};
