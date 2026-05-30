require "rails_helper"

RSpec.describe "API authentication", type: :request do
  fixtures :users, :tasks

  describe "protected endpoints" do
    context "without a token" do
      before do
        get tasks_path,
            params: { scheduled_from: "2026-05-24", scheduled_to: "2026-05-28" },
            headers: { "Authorization" => "" }
      end

      it { expect(response).to have_http_status(:unauthorized) }
      it { expect(json["error"]).to eq("Unauthorized") }
    end

    it "returns unauthorized with an invalid token" do
      get tasks_path,
          params: { scheduled_from: "2026-05-24", scheduled_to: "2026-05-28" },
          headers: { "Authorization" => "Bearer invalid-token" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
