import { logError, logQuery } from '../logger';
import type { CFXCallback, CFXParameters, QueryType } from '../types';
import { parseResponse } from '../utils/parseResponse';
import { executeType, parseExecute } from '../utils/parseExecute';
import { parseArguments } from '../utils/parseArguments';
import { getConnection } from './connection';
import { setCallback } from '../utils/setCallback';
import { performance } from 'perf_hooks';
import validateResultSet from '../utils/validateResultSet';
import { profileBatchStatements, runProfiler } from '../profiler';

export const rawExecute = async (
  invokingResource: string,
  originalQuery: string,
  parameters: CFXParameters,
  cb?: CFXCallback,
  isPromise?: boolean,
  unpack?: boolean,
  connectionId?: number,
) => {
  cb = setCallback(parameters, cb);

  let type: QueryType;
  let placeholders: number;

  try {
    type = executeType(originalQuery);
    placeholders = originalQuery.split('?').length - 1;
    parameters = parseExecute(placeholders, parameters);
  } catch (err: any) {
    return logError(invokingResource, cb, isPromise, err, originalQuery, parameters);
  }

  await using connection = await getConnection(connectionId);

  if (!connection) return;

  try {
    const hasProfiler = await runProfiler(connection, invokingResource);
    const parametersLength = parameters.length == 0 ? 1 : parameters.length;
    const response = [] as any[];
    const durations = [] as number[];

    for (let index = 0; index < parametersLength; index++) {
      let values = parameters[index];

      if (values && placeholders > values.length) {
        for (let i = values.length; i < placeholders; i++) {
          values[i] = null;
        }
      }

      // Parse query per iteration to translate ? to $1 and format values
      let query: string;
      try {
        const parsed = parseArguments(originalQuery, values);
        query = parsed[0];
        values = parsed[1];
      } catch (err: any) {
         return logError(invokingResource, cb, isPromise, err, originalQuery, values);
      }

      const startTime = performance.now();
      const result = await connection.execute(query, values);
      const duration = performance.now() - startTime;
      durations.push(duration);

      if (Array.isArray(result) && result.length > 1) {
        for (const value of result) {
          response.push(unpack ? parseResponse(type, value as any) : value);
        }
      } else {
        response.push(unpack ? parseResponse(type, result) : result);
      }

      if (hasProfiler && ((index > 0 && index % 100 === 0) || index === parametersLength - 1)) {
        await profileBatchStatements(connection, invokingResource, query, parameters, index < 100 ? 0 : index, durations);
      } else if (!hasProfiler) {
        logQuery(invokingResource, query, duration, values);
      }

      validateResultSet(invokingResource, query, result);
    }

    if (!cb) return response.length === 1 ? response[0] : response;

    try {
      if (response.length === 1) {
        if (unpack && type === null) {
          if (response[0][0] && Object.keys(response[0][0]).length === 1) {
            cb(Object.values(response[0][0])[0]);
          } else cb(response[0][0]);
        } else {
          cb(response[0]);
        }
      } else {
        cb(response);
      }
    } catch (err) {
      if (typeof err === 'string') {
        if (err.includes('SCRIPT ERROR:')) return console.log(err);
        console.log(`^1SCRIPT ERROR in invoking resource ${invokingResource}: ${err}^0`);
      }
    }
  } catch (err: any) {
    logError(invokingResource, cb, isPromise, err, originalQuery, parameters);
  }
};
