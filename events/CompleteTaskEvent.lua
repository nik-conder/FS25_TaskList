CompleteTaskEvent = {}
local CompleteTaskEvent_mt = Class(CompleteTaskEvent, Event)

InitEventClass(CompleteTaskEvent, "CompleteTaskEvent")

function CompleteTaskEvent.emptyNew()
    return Event.new(CompleteTaskEvent_mt)
end

function CompleteTaskEvent.new(groupId, taskId)
    local self = CompleteTaskEvent.emptyNew()
    self.groupId = groupId
    self.taskId = taskId
    return self
end

function CompleteTaskEvent:writeStream(streamId, connection)
    streamWriteString(streamId, self.groupId)
    streamWriteString(streamId, self.taskId)
end

function CompleteTaskEvent:readStream(streamId, connection)
    self.groupId = streamReadString(streamId)
    self.taskId = streamReadString(streamId)

    self:run(connection)
end

function CompleteTaskEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(CompleteTaskEvent.new(self.groupId, self.taskId))
    end

    local key = self.groupId .. "_" .. self.taskId
    g_currentMission.taskList.activeTasks[key] = nil

    -- Find the origin task and if it should not recur, delete it
    local sourceTask = g_currentMission.taskList.taskGroups[self.groupId].tasks[self.taskId]
    if sourceTask ~= nil and sourceTask.shouldRecur == false then
        g_currentMission.taskList.taskGroups[self.groupId].tasks[self.taskId] = nil
        g_messageCenter:publish(MessageType.TASK_GROUPS_UPDATED)
    end

    g_messageCenter:publish(MessageType.ACTIVE_TASKS_UPDATED)
end
