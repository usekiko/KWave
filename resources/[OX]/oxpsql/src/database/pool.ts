import { getConnectionOptions, pgsql_transaction_isolation_level } from '../config';
import pg from 'pg';
const { Pool } = pg;

export let pool: pg.Pool;
export let dbVersion = '';

export async function createConnectionPool() {
  const config = getConnectionOptions();

  try {
    const dbPool = new Pool(config);

    dbPool.on('connect', (client) => {
      client.query(pgsql_transaction_isolation_level).catch(() => {});
    });

    const result = await dbPool.query('SELECT version() as version');
    dbVersion = result.rows[0].version;

    console.log(`^2Database server connection established!^0`);
    console.log(`^4${dbVersion}^0`);

    pool = dbPool;
  } catch (err: any) {
    console.log(
      `^3Unable to establish a connection to the database (${err.code})!\n^1Error${
        err.errno ? ` ${err.errno}` : ''
      }: ${err.message}^0`,
    );

    if (config.password) config.password = '******';

    console.log(config);
  }
}
