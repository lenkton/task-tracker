class TaskSerializer
  def self.collection(tasks)
    tasks.map { |task| call(task) }
  end

  def self.call(task)
    {
      id: task.id,
      name: task.name,
      description: task.description,
      scheduled_at: task.scheduled_at,
      status: task.status.name,
      tags: task.tags.map(&:name).sort,
      repetition_type: task.api_repetition_type,
      repetition_data: task.repetition_data,
      repetition_event_number: task.repetition_event_number,
      created_at: task.created_at,
      updated_at: task.updated_at
    }
  end
end
