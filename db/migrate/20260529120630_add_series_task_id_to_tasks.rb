class AddSeriesTaskIdToTasks < ActiveRecord::Migration[8.1]
  def change
    add_reference :tasks, :series_task, null: true, foreign_key: { to_table: :tasks, on_delete: :cascade }

    add_index :tasks,
              [ :series_task_id, :repetition_event_number ],
              unique: true,
              where: "series_task_id IS NOT NULL",
              name: "index_tasks_on_series_task_id_and_repetition_event_number"
  end
end
