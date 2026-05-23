require "rails_helper"

RSpec.describe "Tasks API", type: :request do
  fixtures :tasks, :statuses

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
    before { get tasks_path, as: :json }

    it { expect(response).to have_http_status(:ok) }
    it { expect(json.length).to eq(2) }

    it "returns fixture task names" do
      expect(json.map { |item| item["name"] })
        .to include("Review pull requests", "Implement task tracker API")
    end

    it "includes status for review task" do
      review_task = json.find { |item| item["name"] == "Review pull requests" }

      expect(review_task["status"]).to eq("todo")
    end
  end

  describe "GET /tasks/:id" do
    context "when task exists" do
      before { get task_path(task), as: :json }

      it { expect(response).to have_http_status(:ok) }
      it { expect(json["id"]).to eq(task.id) }
      it { expect(json["name"]).to eq("Review pull requests") }
      it { expect(json["status"]).to eq("todo") }
    end

    context "when task is missing" do
      before { get task_path(id: 0), as: :json }

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
      end
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
