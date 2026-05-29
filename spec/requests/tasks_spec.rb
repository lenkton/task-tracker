require "rails_helper"

RSpec.describe "Tasks API", type: :request do
  fixtures :tasks, :statuses, :tags, :tags_tasks

  let(:task) { tasks(:one) }

  let(:valid_task_params) do
    {
      name: "Write tests",
      description: "Cover tasks API",
      scheduled_at: "2026-05-26T09:00:00Z",
      status: "todo"
    }
  end

  describe "GET /tasks" do
    let(:interval_params) { { scheduled_from: "2026-05-24", scheduled_to: "2026-05-28" } }

    context "without interval params" do
      before { get tasks_path }

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(json["errors"]).to include("scheduled_from", "scheduled_to") }
    end

    context "with interval params" do
      before { get tasks_path, params: interval_params }

      it { expect(response).to have_http_status(:ok) }

      it "returns one-time and expanded recurring tasks" do
        expect(json.map { |item| item["name"] }).to include(
          "Review pull requests",
          "Implement task tracker API",
          "Daily standup"
        )
      end

      it "assigns repetition_event_number to generated occurrences" do
        standup_events = json.select { |item| item["name"] == "Daily standup" }

        expect(standup_events.map { |item| item["repetition_event_number"] }).to eq([ 3, 4, 5 ])
      end
    end

    context "with statuses filter" do
      subject!(:fetch_tasks) { get tasks_path, params: interval_params.merge(statuses: "todo") }

      it { expect(response).to have_http_status(:ok) }
      it { expect(json.map { |item| item["name"] }).not_to include("Implement task tracker API") }
    end

    context "with invalid scheduled_from" do
      subject!(:fetch_tasks) do
        get tasks_path, params: { scheduled_from: "not-a-date", scheduled_to: "2026-05-28" }
      end

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(json["errors"]).to include("scheduled_from") }
    end
  end

  describe "GET /tasks/:id" do
    context "when task exists" do
      before { get task_path(task) }

      it { expect(response).to have_http_status(:ok) }
      it { expect(json["id"]).to eq(task.id) }
      it { expect(json["name"]).to eq("Review pull requests") }
      it { expect(json["status"]).to eq("todo") }
      it { expect(json["tags"]).to eq([ "операции", "отчетность" ]) }
      it { expect(json["repetition_type"]).to eq("one_time") }
      it { expect(json["repetition_data"]).to eq({}) }
      it { expect(json["repetition_event_number"]).to eq(0) }
    end

    context "when task is missing" do
      before { get task_path(id: 0) }

      it { expect(response).to have_http_status(:not_found) }
    end
  end

  describe "POST /tasks" do
    context "with valid params" do
      it "creates a task" do
        expect {
          post tasks_path, params: valid_task_params, as: :json
        }.to change(Task, :count).by(1)
      end

      context "when submitted" do
        before { post tasks_path, params: valid_task_params, as: :json }

        it { expect(response).to have_http_status(:created) }
        it { expect(json["name"]).to eq("Write tests") }
        it { expect(json["status"]).to eq("todo") }
        it { expect(json["repetition_type"]).to eq("one_time") }
        it { expect(json["repetition_data"]).to eq({}) }
        it { expect(json["repetition_event_number"]).to eq(0) }
      end
    end

    context "with daily repetition" do
      let(:daily_task_params) do
        valid_task_params.merge(
          repetition_type: "daily",
          repetition_data: { period: 2 }
        )
      end

      context "when submitted" do
        before { post tasks_path, params: daily_task_params, as: :json }

        it { expect(response).to have_http_status(:created) }
        it { expect(json["repetition_type"]).to eq("daily") }
        it { expect(json["repetition_data"]).to eq({ "period" => 2 }) }
        it { expect(Task.last).to be_a(Task::Daily) }
      end
    end

    context "with monthly repetition" do
      let(:monthly_task_params) do
        valid_task_params.merge(
          repetition_type: "monthly",
          repetition_data: { day_of_month: 15 }
        )
      end

      context "when submitted" do
        before { post tasks_path, params: monthly_task_params, as: :json }

        it { expect(response).to have_http_status(:created) }
        it { expect(json["repetition_type"]).to eq("monthly") }
        it { expect(json["repetition_data"]).to eq({ "day_of_month" => 15 }) }
      end
    end

    context "with odd_even repetition" do
      let(:odd_even_task_params) do
        valid_task_params.merge(
          repetition_type: "odd_even",
          repetition_data: { parity: "odd" }
        )
      end

      context "when submitted" do
        before { post tasks_path, params: odd_even_task_params, as: :json }

        it { expect(response).to have_http_status(:created) }
        it { expect(json["repetition_type"]).to eq("odd_even") }
        it { expect(json["repetition_data"]).to eq({ "parity" => "odd" }) }
      end
    end

    context "with invalid repetition_type" do
      subject!(:create_task) do
        post tasks_path, params: valid_task_params.merge(repetition_type: "weekly"), as: :json
      end

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(json["errors"]).to include("repetition_type") }
    end

    context "with invalid repetition_data for daily" do
      subject!(:create_task) do
        post tasks_path, params: valid_task_params.merge(repetition_type: "daily", repetition_data: {}), as: :json
      end

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(json["errors"]).to include("repetition_data") }
    end

    context "when repetition_event_number is sent on create" do
      before do
        post tasks_path, params: valid_task_params.merge(repetition_event_number: 5), as: :json
      end

      it { expect(response).to have_http_status(:created) }
      it { expect(json["repetition_event_number"]).to eq(0) }
    end

    context "with invalid params" do
      let(:invalid_task_params) { { name: "", status: "todo" } }

      it "does not create a task" do
        expect {
          post tasks_path, params: invalid_task_params, as: :json
        }.not_to change(Task, :count)
      end

      context "when submitted" do
        before { post tasks_path, params: invalid_task_params, as: :json }

        it { expect(response).to have_http_status(:unprocessable_content) }
        it { expect(json["errors"]).to include("name", "scheduled_at") }
      end
    end

    context "with tags" do
      let(:tagged_task_params) { valid_task_params.merge(tags: [ "отчетность", "новый тег" ]) }

      it "creates unknown tags" do
        expect {
          post tasks_path, params: tagged_task_params, as: :json
        }.to change(Tag, :count).by(1)
      end

      context "when submitted" do
        before { post tasks_path, params: tagged_task_params, as: :json }

        it { expect(response).to have_http_status(:created) }
        it { expect(json["tags"]).to contain_exactly("отчетность", "новый тег") }
      end
    end

    context "with invalid status" do
      let(:invalid_status_params) { valid_task_params.merge(status: "nonexistent") }

      it "does not create a task" do
        expect {
          post tasks_path, params: invalid_status_params, as: :json
        }.not_to change(Task, :count)
      end

      context "when submitted" do
        before { post tasks_path, params: invalid_status_params, as: :json }

        it { expect(response).to have_http_status(:unprocessable_content) }
        it { expect(json["errors"]).to include("status") }
      end
    end
  end

  describe "PATCH /tasks/:id" do
    context "with valid params" do
      before { patch task_path(task), params: { name: "Updated task name" }, as: :json }

      it { expect(response).to have_http_status(:ok) }
      it { expect(json["name"]).to eq("Updated task name") }
      it { expect(task.reload.name).to eq("Updated task name") }
    end

    context "with invalid params" do
      before { patch task_path(task), params: { name: "" }, as: :json }

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(json["errors"]).to include("name") }
      it { expect(task.reload.name).to eq("Review pull requests") }
    end

    context "with tags" do
      context "when fewer tags are sent" do
        subject!(:update_task) { patch task_path(task), params: { tags: [ "звонок" ] }, as: :json }

        it { expect(response).to have_http_status(:ok) }
        it { expect(json["tags"]).to eq([ "звонок" ]) }
        it { expect(task.reload.tags.map(&:name)).to eq([ "звонок" ]) }
        it { expect(task.tags.map(&:name)).not_to include("отчетность") }
        it { expect(task.tags.map(&:name)).not_to include("операции") }
      end

      context "when tags are cleared" do
        subject!(:update_task) { patch task_path(task), params: { tags: [] }, as: :json }

        it { expect(response).to have_http_status(:ok) }
        it { expect(json["tags"]).to eq([]) }
        it { expect(task.reload.tags).to be_empty }
      end
    end

    context "with invalid status" do
      it "does not update the task status" do
        patch task_path(task), params: { status: "nonexistent" }, as: :json

        expect(task.reload.status.name).to eq("todo")
      end

      context "when submitted" do
        before { patch task_path(task), params: { status: "nonexistent" }, as: :json }

        it { expect(response).to have_http_status(:unprocessable_content) }
        it { expect(json["errors"]).to include("status") }
      end
    end
  end

  describe "DELETE /tasks/:id" do
    it "destroys a task" do
      expect {
        delete task_path(task), as: :json
      }.to change(Task, :count).by(-1)
    end

    context "when deleted" do
      before { delete task_path(task), as: :json }

      it { expect(response).to have_http_status(:no_content) }
      it { expect(response.body).to be_empty }
      it { expect(Task.find_by(id: task.id)).to be_nil }
    end
  end
end
