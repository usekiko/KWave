import type { CFXCallback, CFXParameters, TransactionQuery } from './types';
import { rawQuery, rawExecute, rawTransaction, pool } from './database';
import { startTransaction } from './database/startTransaction';
import { sleep } from './utils/sleep';
import('./update');

const PostgreSQL = {
  isReady: () => {
    return pool ? true : false;
  },

  awaitConnection: async () => {
    while (!pool) await sleep(0);

    return true;
  },

  query: (
    query: string,
    parameters: CFXParameters = [],
    cb: CFXCallback,
    invokingResource = GetInvokingResource(),
    isPromise?: boolean,
  ) => {
    rawQuery(null, invokingResource, query, parameters, cb, isPromise);
  },

  single: (
    query: string,
    parameters: CFXParameters = [],
    cb: CFXCallback,
    invokingResource = GetInvokingResource(),
    isPromise?: boolean,
  ) => {
    rawQuery('single', invokingResource, query, parameters, cb, isPromise);
  },

  scalar: (
    query: string,
    parameters: CFXParameters = [],
    cb: CFXCallback,
    invokingResource = GetInvokingResource(),
    isPromise?: boolean,
  ) => {
    rawQuery('scalar', invokingResource, query, parameters, cb, isPromise);
  },

  update: (
    query: string,
    parameters: CFXParameters = [],
    cb: CFXCallback,
    invokingResource = GetInvokingResource(),
    isPromise?: boolean,
  ) => {
    rawQuery('update', invokingResource, query, parameters, cb, isPromise);
  },

  insert: (
    query: string,
    parameters: CFXParameters = [],
    cb: CFXCallback,
    invokingResource = GetInvokingResource(),
    isPromise?: boolean,
  ) => {
    rawQuery('insert', invokingResource, query, parameters, cb, isPromise);
  },

  transaction: (
    queries: TransactionQuery,
    parameters: CFXParameters = [],
    cb: CFXCallback,
    invokingResource = GetInvokingResource(),
    isPromise?: boolean,
  ) => {
    rawTransaction(invokingResource, queries, parameters, cb, isPromise);
  },

  startTransaction: (transactions: () => Promise<boolean>, invokingResource = GetInvokingResource()) => {
    console.warn(`startTransaction is "experimental" and may receive breaking changes.`);
    return startTransaction(invokingResource, transactions, undefined, true);
  },

  prepare: (
    query: string,
    parameters: CFXParameters = [],
    cb: CFXCallback,
    invokingResource = GetInvokingResource(),
    isPromise?: boolean,
  ) => {
    rawExecute(invokingResource, query, parameters, cb, isPromise, true);
  },

  rawExecute: (
    query: string,
    parameters: CFXParameters = [],
    cb: CFXCallback,
    invokingResource = GetInvokingResource(),
    isPromise?: boolean,
  ) => {
    rawExecute(invokingResource, query, parameters, cb, isPromise);
  },
};

function provide(resourceName: string, method: string, cb: Function) {
  on(`__cfx_export_${resourceName}_${method}`, (setCb: Function) => setCb(cb));
}

const exports = global.exports;

for (const key in PostgreSQL) {
  const exp = (PostgreSQL as any)[key];

  const async_exp = (query: string, parameters: CFXParameters = [], invokingResource = GetInvokingResource()) => {
    return new Promise((resolve, reject) => {
      exp(
        query,
        parameters,
        (result: unknown, err: string) => {
          if (err) return reject(new Error(err));
          resolve(result);
        },
        invokingResource,
        true,
      );
    });
  };

  try {
    exports(key, exp);
    exports(`${key}_async`, async_exp);
    exports(`${key}Sync`, async_exp);

    provide('pgsql', key, exp);
    provide('pgsql', `${key}_async`, async_exp);
    provide('pgsql', `${key}Sync`, async_exp);

    provide('oxpsql', key, exp);
    provide('oxpsql', `${key}_async`, async_exp);
    provide('oxpsql', `${key}Sync`, async_exp);
  } catch {}
}

export default PostgreSQL;
