class TaskSerializer
  def self.collection(items)
    items.map { |item| call(item) }
  end

  def self.call(item)
    task, scheduled_at, event_number = extract(item)

    if list_occurrence?(item, task)
      return list_occurrence_payload(task, scheduled_at)
    end

    {
      id: task.id,
      name: task.name,
      description: task.description,
      scheduled_at: scheduled_at,
      status: task.status.name,
      tags: task.tags.map(&:name).sort,
      repetition_type: task.api_repetition_type,
      repetition_data: task.repetition_data,
      repetition_event_number: event_number,
      series_task_id: task.series_task_id,
      created_at: task.created_at,
      updated_at: task.updated_at
    }
  end

  def self.list_occurrence_payload(task, scheduled_at)
    {
      id: task.id,
      name: task.name,
      description: task.description,
      scheduled_at: scheduled_at,
      status: task.status.name,
      tags: task.tags.map(&:name).sort,
      repetition_type: "one_time",
      repetition_data: {},
      repetition_event_number: 0,
      series_task_id: nil,
      created_at: task.created_at,
      updated_at: task.updated_at
    }
  end
  private_class_method :list_occurrence_payload

  def self.list_occurrence?(item, task)
    item.is_a?(Tasks::Occurrence) && task.is_a?(Task::CustomizedEvent)
  end
  private_class_method :list_occurrence?

  def self.extract(item)
    if item.is_a?(Tasks::Occurrence)
      [ item.task, item.scheduled_at, item.event_number ]
    else
      [ item, item.scheduled_at, item.repetition_event_number ]
    end
  end
  private_class_method :extract
end
