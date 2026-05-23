class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :name, null: false
      t.text :description, null: false, default: ""
      t.datetime :scheduled_at, null: false
      t.references :status, null: false, foreign_key: true

      t.timestamps
    end
  end
end
