import type { PoolClient } from 'pg';
import { scheduleTick } from '../utils/scheduleTick';
import { sleep } from '../utils/sleep';
import { pool } from './pool';
import type { CFXParameters } from '../types';

(Symbol as any).dispose ??= Symbol('Symbol.dispose');
(Symbol as any).asyncDispose ??= Symbol('Symbol.asyncDispose');

let connectionCounter = 1;
const activeConnections: Record<string, PgSql> = {};

export class PgSql {
  id: number;
  connection: PoolClient;
  transaction?: boolean;

  constructor(connection: PoolClient) {
    this.id = connectionCounter++;
    this.connection = connection;
    activeConnections[this.id] = this;
  }

  async query(query: string, values: CFXParameters = []) {
    scheduleTick();
    return await this.connection.query(query, values as any);
  }

  async execute(query: string, values: CFXParameters = []) {
    scheduleTick();
    return await this.connection.query(query, values as any);
  }

  async beginTransaction() {
    this.transaction = true;
    return this.connection.query('BEGIN');
  }

  async rollback() {
    delete this.transaction;
    return this.connection.query('ROLLBACK');
  }

  async commit() {
    delete this.transaction;
    return this.connection.query('COMMIT');
  }

  async [Symbol.asyncDispose]() {
    // never silently commit a transaction the caller left open; roll it back
    if (this.transaction) await this.rollback().catch(() => {});

    delete activeConnections[this.id];
    this.connection.release();
  }
}

export async function getConnection(connectionId?: number) {
  while (!pool) await sleep(0);

  if (connectionId) {
    const existing = activeConnections[connectionId];
    if (!existing) return;

    // Borrowed connection: its owner is responsible for commit/rollback and
    // release, so the borrow site must not dispose it. Hand back a non-owning
    // view whose disposer is a no-op.
    return Object.assign(Object.create(Object.getPrototypeOf(existing)) as PgSql, existing, {
      async [Symbol.asyncDispose]() {},
    });
  }

  return new PgSql(await pool.connect());
}
