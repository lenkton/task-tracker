require "rails_helper"

RSpec.describe User, type: :model do
  fixtures :users

  describe "validations" do
    it "is valid with valid attributes" do
      expect(User.new(email: "new@example.com", name: "New User")).to be_valid
    end

    it "requires email" do
      user = User.new(name: "No Email")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it "requires unique email" do
      user = User.new(email: users(:one).email, name: "Duplicate")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("has already been taken")
    end

    it "normalizes email" do
      user = User.create!(email: "  MixedCase@Example.COM  ", name: "Mixed")
      expect(user.email).to eq("mixedcase@example.com")
    end
  end

  describe "auth token" do
    it "is generated on create" do
      user = User.create!(email: "token@example.com", name: "Token User")
      expect(user.auth_token).to be_present
    end
  end
end
