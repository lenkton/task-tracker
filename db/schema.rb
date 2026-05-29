# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_30_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "statuses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_statuses_on_name", unique: true
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "tags_tasks", id: false, force: :cascade do |t|
    t.bigint "tag_id", null: false
    t.bigint "task_id", null: false
    t.index ["tag_id", "task_id"], name: "index_tags_tasks_on_tag_id_and_task_id", unique: true
    t.index ["task_id", "tag_id"], name: "index_tags_tasks_on_task_id_and_tag_id", unique: true
  end

  create_table "tasks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", default: "", null: false
    t.string "name", null: false
    t.jsonb "repetition_data", default: {}, null: false
    t.integer "repetition_event_number", default: 0, null: false
    t.string "repetition_type", default: "Task::OneTime", null: false
    t.datetime "scheduled_at", null: false
    t.bigint "series_task_id"
    t.bigint "status_id", null: false
    t.datetime "updated_at", null: false
    t.index ["series_task_id", "repetition_event_number"], name: "index_tasks_on_series_task_id_and_repetition_event_number", unique: true, where: "(series_task_id IS NOT NULL)"
    t.index ["series_task_id"], name: "index_tasks_on_series_task_id"
    t.index ["status_id"], name: "index_tasks_on_status_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "auth_token", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["auth_token"], name: "index_users_on_auth_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "tasks", "statuses"
  add_foreign_key "tasks", "tasks", column: "series_task_id", on_delete: :cascade
end
