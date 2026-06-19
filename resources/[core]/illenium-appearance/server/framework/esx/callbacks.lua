if not Framework.ESX() then return end

local ESX = exports["kw_core"]:getSharedObject()

ESX.RegisterServerCallback("kw_skin:getPlayerSkin", function(source, cb)
	local Player = ESX.GetPlayerFromId(source)

    local appearance = Framework.GetAppearance(Player.identifier)

    cb(appearance, {
        skin_male = Player.job.skin_male,
        skin_female = Player.job.skin_female
    })
end)

lib.callback.register("illenium-appearance:server:esx:getGradesForJob", function(_, jobName)
    return Database.JobGrades.GetByJobName(jobName)
end)
