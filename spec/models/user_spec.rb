require "rails_helper"

RSpec.describe User, type: :model do
  fixtures :users

  describe "validations" do
    it "is valid with valid attributes" do
      expect(described_class.new(email: "new@example.com", name: "New User")).to be_valid
    end

    context "when email is missing" do
      subject(:user) { described_class.new(name: "No Email") }

      before { user.valid? }

      it { expect(user).not_to be_valid }
      it { expect(user.errors[:email]).to include("can't be blank") }
    end

    context "when email is not unique" do
      subject(:user) { described_class.new(email: users(:one).email, name: "Duplicate") }

      before { user.valid? }

      it { expect(user).not_to be_valid }
      it { expect(user.errors[:email]).to include("has already been taken") }
    end

    it "normalizes email" do
      user = described_class.create!(email: "  MixedCase@Example.COM  ", name: "Mixed")
      expect(user.email).to eq("mixedcase@example.com")
    end
  end

  describe "auth token" do
    it "is generated on create" do
      user = described_class.create!(email: "token@example.com", name: "Token User")
      expect(user.auth_token).to be_present
    end
  end
end
