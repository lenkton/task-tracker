# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
%w[todo in_progress done cancelled].each do |status_name|
  Status.find_or_create_by!(name: status_name)
end

%w[отчетность операции звонок].each do |tag_name|
  Tag.find_or_create_by!(name: tag_name)
end

if Rails.env.development?
  [
    {
      name: "Review pull requests",
      description: "Check open PRs on GitHub",
      scheduled_at: 1.day.from_now,
      status_name: "todo"
    },
    {
      name: "Implement task tracker API",
      description: "Add CRUD endpoints for tasks",
      scheduled_at: 2.days.from_now,
      status_name: "in_progress"
    }
  ].each do |attrs|
    status = Status.find_by!(name: attrs[:status_name])
    Task.find_or_create_by!(name: attrs[:name]) do |task|
      task.description = attrs[:description]
      task.scheduled_at = attrs[:scheduled_at]
      task.status = status
    end
  end
end
