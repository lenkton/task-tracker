require "rails_helper"

RSpec.describe "API authentication", type: :request do
  fixtures :users, :tasks

  describe "protected endpoints" do
    it "returns unauthorized without a token" do
      get tasks_path,
          params: { scheduled_from: "2026-05-24", scheduled_to: "2026-05-28" },
          headers: { "Authorization" => "" }

      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to eq("Unauthorized")
    end

    it "returns unauthorized with an invalid token" do
      get tasks_path,
          params: { scheduled_from: "2026-05-24", scheduled_to: "2026-05-28" },
          headers: { "Authorization" => "Bearer invalid-token" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
