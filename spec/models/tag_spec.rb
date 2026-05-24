require "rails_helper"

RSpec.describe Tag do
  fixtures :tags

  describe "system tags" do
    let(:system_tag) { tags(:reporting) }
    let(:custom_tag) { tags(:custom) }

    describe "update" do
      subject!(:update_tag) { system_tag.update(name: "новое имя") }

      it { expect(update_tag).to be(false) }
      it { expect(system_tag.errors[:base]).to include("system tags cannot be modified") }
      it { expect(system_tag.reload.name).to eq("отчетность") }
    end

    describe "destroy" do
      before { system_tag.destroy }

      it { expect(described_class.exists?(system_tag.id)).to be(true) }
      it { expect(system_tag.errors[:base]).to include("system tags cannot be deleted") }
    end
  end

  describe "custom tags" do
    let(:custom_tag) { tags(:custom) }

    it "allows updating" do
      custom_tag.update(name: "переименовано")

      expect(custom_tag.reload.name).to eq("переименовано")
    end

    it "allows destroying" do
      expect { custom_tag.destroy }.to change(described_class, :count).by(-1)
    end
  end
end
