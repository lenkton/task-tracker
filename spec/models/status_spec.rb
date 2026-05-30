require "rails_helper"

RSpec.describe Status do
  fixtures :statuses

  describe "protected statuses" do
    let(:deleted_status) { statuses(:deleted) }
    let(:todo_status) { statuses(:todo) }

    describe "update" do
      subject!(:update_status) { deleted_status.update(name: "removed") }

      it { expect(update_status).to be(false) }
      it { expect(deleted_status.errors[:base]).to include("protected statuses cannot be modified") }
      it { expect(deleted_status.reload.name).to eq("deleted") }
    end

    describe "destroy" do
      before { deleted_status.destroy }

      it { expect(described_class.exists?(deleted_status.id)).to be(true) }
      it { expect(deleted_status.errors[:base]).to include("protected statuses cannot be deleted") }
    end
  end

  describe "other statuses" do
    let(:todo_status) { statuses(:todo) }

    it "allows updating" do
      todo_status.update(name: "backlog")

      expect(todo_status.reload.name).to eq("backlog")
    end

    it "allows destroying when no tasks reference it" do
      status = Status.create!(name: "temporary")

      expect { status.destroy }.to change(described_class, :count).by(-1)
    end
  end
end
