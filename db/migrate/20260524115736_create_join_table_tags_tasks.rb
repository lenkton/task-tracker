class CreateJoinTableTagsTasks < ActiveRecord::Migration[8.1]
  def change
    create_join_table :tags, :tasks do |t|
      t.index [ :tag_id, :task_id ], unique: true
      t.index [ :task_id, :tag_id ], unique: true
    end
  end
end
