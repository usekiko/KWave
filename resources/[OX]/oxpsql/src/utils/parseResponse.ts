import type { QueryResult } from 'pg';
import type { QueryResponse, QueryType } from '../types';

export const parseResponse = (type: QueryType, result: QueryResponse): any => {
  const queryResult = result as unknown as QueryResult;

  switch (type) {
    case 'insert':
      if (queryResult?.rows?.length > 0) {
        const row = queryResult.rows[0];
        if (row.id !== undefined) return row.id;
        return Object.values(row)[0] ?? null;
      }
      return queryResult?.rowCount ?? null;

    case 'update':
      return queryResult?.rowCount ?? null;

    case 'single':
      return queryResult?.rows?.[0] ?? null;

    case 'scalar':
      const row = queryResult?.rows?.[0];
      return (row && Object.values(row)[0]) ?? null;

    default:
      if (queryResult && queryResult.command && queryResult.command !== 'SELECT' && queryResult.command !== 'WITH') {
        const insertId = queryResult.rows?.[0] ? (queryResult.rows[0].id ?? Object.values(queryResult.rows[0])[0]) : 0;
        return {
          insertId: insertId,
          affectedRows: queryResult.rowCount ?? 0,
          warningStatus: 0,
          changedRows: queryResult.rowCount ?? 0
        };
      }
      return queryResult?.rows ?? [];
  }
};
