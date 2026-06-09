import type { PoolConfig } from 'pg';

export const pgsql_connection_string =
  GetConvar('pgsql_connection_string', '') || process.env.DB_CONNECTION || 'postgresql://root@localhost/postgres';
export let pgsql_ui = GetConvar('pgsql_ui', 'false') === 'true';
export let pgsql_slow_query_warning = GetConvarInt('pgsql_slow_query_warning', 200);
export let pgsql_debug: boolean | string[] = false;

// max array size of individual resource query logs
// prevent excessive memory use when people use debug/ui in production
export let pgsql_log_size = 0;

export function setDebug() {
  pgsql_ui = GetConvar('pgsql_ui', 'false') === 'true';
  pgsql_slow_query_warning = GetConvarInt('pgsql_slow_query_warning', 200);

  try {
    const debug = GetConvar('pgsql_debug', 'false');
    pgsql_debug = debug === 'false' ? false : JSON.parse(debug);
  } catch (e) {
    pgsql_debug = true;
  }

  pgsql_log_size = pgsql_debug ? 10000 : GetConvarInt('pgsql_log_size', 100);
}

export function getIsolationLevelStatement(level: number) {
  const query = 'SET TRANSACTION ISOLATION LEVEL';
  switch (level) {
    case 1:
      return `${query} REPEATABLE READ`;
    case 2:
      return `${query} READ COMMITTED`;
    case 3:
      return `${query} READ UNCOMMITTED`;
    case 4:
      return `${query} SERIALIZABLE`;
    default:
      return `${query} READ COMMITTED`;
  }
}

export const pgsql_transaction_isolation_level = getIsolationLevelStatement(
  GetConvarInt('pgsql_transaction_isolation_level', 2),
);

function parseUri(connectionString: string) {
  const splitMatchGroups = connectionString.match(
    new RegExp(
      '^(?:([^:/?#.]+):)?(?://(?:([^/?#]*)@)?([\\w\\d\\-\\u0100-\\uffff.%]*)(?::([0-9]+))?)?([^?#]+)?(?:\\?([^#]*))?$',
    ),
  ) as RegExpMatchArray;

  if (!splitMatchGroups) throw new Error(`pgsql_connection_string structure was invalid (${connectionString})`);

  const authTarget = splitMatchGroups[2] ? splitMatchGroups[2].split(':') : [];

  const options: Record<string, any> = {
    user: authTarget[0] || undefined,
    password: authTarget[1] || undefined,
    host: splitMatchGroups[3],
    port: parseInt(splitMatchGroups[4]) || 5432,
    database: splitMatchGroups[5]?.replace(/^\/+/, ''),
    ...(splitMatchGroups[6] &&
      splitMatchGroups[6].split('&').reduce<Record<string, string>>((connectionInfo, parameter) => {
        const [key, value] = parameter.split('=');
        connectionInfo[key] = value;
        return connectionInfo;
      }, {})),
  };

  return options;
}

export function getConnectionOptions(connectionString: string = pgsql_connection_string): PoolConfig {
  const options: Record<string, any> = connectionString.includes('postgres://') || connectionString.includes('postgresql://')
    ? parseUri(connectionString)
    : connectionString
        .replace(/(?:host(?:name)|ip|server|data\s?source|addr(?:ess)?)=/gi, 'host=')
        .replace(/(?:user\s?(?:id|name)?|uid)=/gi, 'user=')
        .replace(/(?:pwd|pass)=/gi, 'password=')
        .replace(/(?:db)=/gi, 'database=')
        .split(';')
        .reduce<Record<string, string>>((connectionInfo, parameter) => {
          const [key, value] = parameter.split('=');
          if (key) connectionInfo[key] = value;
          return connectionInfo;
        }, {});

  for (const key of ['ssl']) {
    const value = options[key];

    if (typeof value === 'string') {
      if (value === 'false' || value === 'disable') {
        options[key] = false;
      } else if (value === 'true' || value === 'require') {
        options[key] = true;
      } else {
        try {
          options[key] = JSON.parse(value);
        } catch (err) {
          console.log(`^3Failed to parse property ${key} in configuration (${err})!^0`);
        }
      }
    }
  }

  return {
    connectionTimeoutMillis: 60000,
    ...options,
  };
}

RegisterCommand(
  'oxpsql_debug',
  (source: number, args: string[]) => {
    if (source !== 0) return console.log('^3This command can only be run server side^0');
    switch (args[0]) {
      case 'add':
        if (!Array.isArray(pgsql_debug)) pgsql_debug = [];
        pgsql_debug.push(args[1]);
        SetConvar('pgsql_debug', JSON.stringify(pgsql_debug));
        return console.log(`^3Added ${args[1]} to pgsql_debug^0`);

      case 'remove':
        if (Array.isArray(pgsql_debug)) {
          const index = pgsql_debug.indexOf(args[1]);
          if (index === -1) return;
          pgsql_debug.splice(index, 1);
          if (pgsql_debug.length === 0) pgsql_debug = false;
          SetConvar('pgsql_debug', JSON.stringify(pgsql_debug) || 'false');
          return console.log(`^3Removed ${args[1]} from pgsql_debug^0`);
        }

      default:
        return console.log(`^3Usage: oxpsql_debug add|remove <resource>^0`);
    }
  },
  true,
);
