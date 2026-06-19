import { pgsql_debug } from '../config';
import type { PgSql } from '../database/connection';
import { logQuery } from '../logger';
import type { CFXParameters } from '../types';

/**
 * PostgreSQL doesn't have an equivalent to MySQL's INFORMATION_SCHEMA.PROFILING.
 * We rely on Node's performance.now() measured at the execution site.
 */
export async function runProfiler(connection: PgSql, invokingResource: string) {
  if (!pgsql_debug) return false;
  if (Array.isArray(pgsql_debug) && !pgsql_debug.includes(invokingResource)) return false;
  return true;
}

export async function profileBatchStatements(
  connection: PgSql,
  invokingResource: string,
  query: string | { query: string; params?: CFXParameters }[],
  parameters: CFXParameters | null,
  offset: number,
  durations?: number[]
) {
  if (!durations || durations.length === 0) return;

  if (typeof query === 'string' && parameters) {
    for (let i = 0; i < durations.length; i++) {
      logQuery(invokingResource, query, durations[i], parameters[offset + i]);
    }
    return;
  }

  if (typeof query === 'object') {
    for (let i = 0; i < durations.length; i++) {
      const transaction = query[offset + i];
      if (!transaction) break;
      logQuery(invokingResource, transaction.query, durations[i], transaction.params);
    }
  }
}
