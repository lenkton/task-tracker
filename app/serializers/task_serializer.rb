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
      created_at: task.created_at,
      updated_at: task.updated_at
    }
  end
end
