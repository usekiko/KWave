import { PgSql, getConnection } from './connection';
import { logError } from '../logger';
import type { CFXCallback, CFXParameters } from '../types';
import { parseArguments } from '../utils/parseArguments';

async function runQuery(conn: PgSql | null, sql: string, values: CFXParameters) {
  let parsedSql, parsedValues;
  [parsedSql, parsedValues] = parseArguments(sql, values);

  try {
    if (!conn) throw new Error(`Connection used by transaction timed out after 30 seconds.`);

    return await conn.query(parsedSql, parsedValues);
  } catch (err: any) {
    throw new Error(`Query: ${parsedSql}\n${JSON.stringify(parsedValues)}\n${err.message}`);
  }
}

export const startTransaction = async (
  invokingResource: string,
  queries: (...args: any[]) => Promise<boolean>,
  cb?: CFXCallback,
  isPromise?: boolean,
) => {
  await using conn: PgSql | undefined = await getConnection();
  let response: boolean | null = false;
  let closed = false;

  if (!conn) return;

  const timeout = setTimeout(() => (closed = true), 30000);

  try {
    await conn.beginTransaction();

    const commit = await queries((sql: string, values: CFXParameters) => runQuery(closed ? null : conn, sql, values));

    if (closed) throw new Error(`Transaction has timed out after 30 seconds.`);

    response = commit === false ? false : true;

    if (response) await conn.commit();
    else await conn.rollback();
  } catch (err: any) {
    await conn.rollback().catch(() => {});
    response = false;
    logError(invokingResource, cb, isPromise, err);
  } finally {
    clearTimeout(timeout);
    closed = true;
  }

  return cb ? cb(response) : response;
};
