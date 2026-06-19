local promise = promise
local Await = Citizen.Await
local resourceName = GetCurrentResourceName()
local GetResourceState = GetResourceState

local options = {
	return_callback_errors = false
}

for i = 1, GetNumResourceMetadata(resourceName, 'pgsql_option') do
	local option = GetResourceMetadata(resourceName, 'pgsql_option', i - 1)
	options[option] = true
end

local function await(fn, query, parameters)
	local p = promise.new()

	fn(nil, query, parameters, function(result, error)
		if error then
			return p:reject(error)
		end

		p:resolve(result)
	end, resourceName, true)

	return Await(p)
end

local type = type
local queryStore = {}

local function safeArgs(query, parameters, cb, transaction)
	local queryType = type(query)

	if queryType == 'number' then
		query = queryStore[query]
		assert(query, "First argument received invalid query store reference")
	elseif transaction then
		if queryType ~= 'table' then
			error(("First argument expected table, received '%s'"):format(query))
		end
	elseif queryType ~= 'string' then
		error(("First argument expected string, received '%s'"):format(query))
	end

	if parameters then
		local paramType = type(parameters)

		if paramType ~= 'table' and paramType ~= 'function' then
			error(("Second argument expected table or function, received '%s'"):format(parameters))
		end

		if paramType == 'function' or parameters.__cfx_functionReference then
			cb = parameters
			parameters = nil
		end
	end

	if cb and parameters then
		local cbType = type(cb)

		if cbType ~= 'function' and (cbType == 'table' and not cb.__cfx_functionReference) then
			error(("Third argument expected function, received '%s'"):format(cb))
		end
	end

	return query, parameters, cb
end

local oxpsql = exports.oxpsql

local pgsql_method_mt = {
	__call = function(self, query, parameters, cb)
		query, parameters, cb = safeArgs(query, parameters, cb, self.method == 'transaction')
		return oxpsql[self.method](nil, query, parameters, cb, resourceName, options.return_callback_errors)
	end
}

local PostgreSQL = setmetatable(PostgreSQL or {}, {
	__index = function(_, index)
		return function(...)
			return oxpsql[index](nil, ...)
		end
	end
})

for _, method in pairs({
	'scalar', 'single', 'query', 'insert', 'update', 'prepare', 'transaction', 'rawExecute',
}) do
	PostgreSQL[method] = setmetatable({
		method = method,
		await = function(query, parameters)
			query, parameters = safeArgs(query, parameters, nil, method == 'transaction')
			return await(oxpsql[method], query, parameters)
		end
	}, pgsql_method_mt)
end

local alias = {
	fetchAll = 'query',
	fetchScalar = 'scalar',
	fetchSingle = 'single',
	insert = 'insert',
	execute = 'update',
	transaction = 'transaction',
	prepare = 'prepare'
}

local alias_mt = {
	__index = function(self, key)
		if alias[key] then
			local method = PostgreSQL[alias[key]]
			PostgreSQL.Async[key] = method
			PostgreSQL.Sync[key] = method.await
			alias[key] = nil
			return self[key]
		end
	end
}

local function addStore(query, cb)
	assert(type(query) == 'string', 'The SQL Query must be a string')

	local storeN = #queryStore + 1
	queryStore[storeN] = query

	return cb and cb(storeN) or storeN
end

PostgreSQL.Sync = setmetatable({ store = addStore }, alias_mt)
PostgreSQL.Async = setmetatable({ store = addStore }, alias_mt)

local function onReady(cb)
	while GetResourceState('oxpsql') ~= 'started' do
		Wait(50)
	end

	oxpsql.awaitConnection()

	return cb and cb() or true
end

PostgreSQL.ready = setmetatable({
	await = onReady
}, {
	__call = function(_, cb)
		Citizen.CreateThreadNow(function() onReady(cb) end)
	end,
})

function PostgreSQL.startTransaction(cb)
	return oxpsql:startTransaction(cb, resourceName)
end

_ENV.PostgreSQL = PostgreSQL
