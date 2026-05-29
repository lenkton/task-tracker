class TaskSerializer
  def self.collection(items)
    items.map { |item| call(item) }
  end

  def self.call(item)
    task, scheduled_at, event_number = extract(item)

    {
      id: api_id_for(task),
      name: task.name,
      description: task.description,
      scheduled_at: scheduled_at,
      status: task.status.name,
      tags: task.tags.map(&:name).sort,
      repetition_type: task.api_repetition_type,
      repetition_data: task.api_repetition_data,
      repetition_event_number: event_number,
      series_task_id: task.series_task_id,
      user_id: task.user_id,
      created_at: task.created_at,
      updated_at: task.updated_at
    }
  end

  def self.api_id_for(task)
    task.is_a?(Task::CustomizedEvent) ? task.series_task_id : task.id
  end
  private_class_method :api_id_for

  def self.extract(item)
    if item.is_a?(Tasks::Occurrence)
      [ item.task, item.scheduled_at, item.event_number ]
    else
      [ item, item.scheduled_at, item.repetition_event_number ]
    end
  end
  private_class_method :extract
end
