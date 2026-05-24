require "rails_helper"

RSpec.describe "Tags API", type: :request do
  fixtures :tags

  let(:custom_tag) { tags(:custom) }
  let(:system_tag) { tags(:reporting) }

  let(:valid_tag_params) { { name: "срочно" } }

  describe "GET /tags" do
    before { get tags_path }

    it { expect(response).to have_http_status(:ok) }
    it { expect(json.length).to eq(4) }
    it { expect(json.map { |item| item["name"] }).to include("отчетность", "на выходных") }
  end

  describe "GET /tags/:id" do
    context "when tag exists" do
      before { get tag_path(custom_tag) }

      it { expect(response).to have_http_status(:ok) }
      it { expect(json["id"]).to eq(custom_tag.id) }
      it { expect(json["name"]).to eq("на выходных") }
      it { expect(json["system"]).to be(false) }
    end

    context "when tag is missing" do
      before { get tag_path(id: 0) }

      it { expect(response).to have_http_status(:not_found) }
    end
  end

  describe "POST /tags" do
    context "with valid params" do
      it "creates a tag" do
        expect {
          post tags_path, params: valid_tag_params, as: :json
        }.to change(Tag, :count).by(1)
      end

      context "when submitted" do
        before { post tags_path, params: valid_tag_params, as: :json }

        it { expect(response).to have_http_status(:created) }
        it { expect(json["name"]).to eq("срочно") }
        it { expect(json["system"]).to be(false) }
      end
    end

    context "with invalid params" do
      subject!(:create_tag) { post tags_path, params: { name: "" }, as: :json }

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(json["errors"]).to include("name") }
    end

    context "with duplicate name" do
      subject!(:create_tag) { post tags_path, params: { name: "на выходных" }, as: :json }

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(json["errors"]).to include("name") }
    end
  end

  describe "PATCH /tags/:id" do
    context "with valid params" do
      subject!(:update_tag) { patch tag_path(custom_tag), params: { name: "переименовано" }, as: :json }

      it { expect(response).to have_http_status(:ok) }
      it { expect(json["name"]).to eq("переименовано") }
      it { expect(custom_tag.reload.name).to eq("переименовано") }
    end

    context "with invalid params" do
      subject!(:update_tag) { patch tag_path(custom_tag), params: { name: "" }, as: :json }

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(json["errors"]).to include("name") }
    end

    context "with system tag" do
      subject!(:update_tag) { patch tag_path(system_tag), params: { name: "новое имя" }, as: :json }

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(json["errors"]).to include("base") }
      it { expect(system_tag.reload.name).to eq("отчетность") }
    end
  end

  describe "DELETE /tags/:id" do
    context "with custom tag" do
      it "destroys a tag" do
        expect {
          delete tag_path(custom_tag), as: :json
        }.to change(Tag, :count).by(-1)
      end
    end

    context "with system tag" do
      subject!(:delete_tag) { delete tag_path(system_tag), as: :json }

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(json["errors"]).to include("base") }
      it { expect(Tag.exists?(system_tag.id)).to be(true) }
    end
  end
end
