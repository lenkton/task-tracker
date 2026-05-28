class AddRepetitionTypeRepetitionDataRepetitionEventNumberToTask < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :repetition_type, :string, null: false, default: 'Task::OneTime'
    add_column :tasks, :repetition_data, :jsonb, null: false, default: {}
    add_column :tasks, :repetition_event_number, :integer, null: false, default: 0
  end
end
