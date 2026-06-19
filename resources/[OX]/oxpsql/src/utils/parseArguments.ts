import type { CFXParameters } from '../types';

export const parseArguments = (query: string, parameters?: CFXParameters | Record<string, any>): [string, any[]] => {
  if (typeof query !== 'string') throw new Error(`Expected query to be a string but received ${typeof query} instead.`);

  let paramsArray: any[] = [];
  let paramIndex = 1;

  if (parameters && typeof parameters === 'object' && !Array.isArray(parameters)) {
    // Named parameters (e.g., :id or @id)
    query = query.replace(/[:@]([a-zA-Z0-9_]+)/g, (match, key) => {
      if (parameters[key] !== undefined) {
        paramsArray.push(parameters[key]);
        return `$${paramIndex++}`;
      }
      return match;
    });
  } else {
    // Array parameters (e.g., ?, ??)
    const paramList = Array.isArray(parameters) ? [...parameters] : [];

    // Replace ?? with double-quoted inline identifiers
    query = query.replace(/\?\?/g, () => {
      const val = paramList.shift();
      if (val === undefined || val === null) return '""';
      return `"${String(val).replace(/"/g, '""')}"`;
    });

    // Replace ? with numbered placeholders $1, $2
    query = query.replace(/\?/g, () => {
      const val = paramList.shift();
      paramsArray.push(val !== undefined ? val : null);
      return `$${paramIndex++}`;
    });
  }

  // Auto-append RETURNING * for INSERT queries to emulate MySQL's insertId,
  // without crashing if the primary key is not named 'id'.
  if (/^\s*INSERT\s+INTO/i.test(query) && !/\bRETURNING\b/i.test(query)) {
    query = query.replace(/;?\s*$/, ' RETURNING *;');
  }

  return [query, paramsArray];
};
