require "rails_helper"

RSpec.describe ServiceResult do
  describe ".success" do
    subject(:result) { described_class.success("ok") }

    it { expect(result).to be_success }
    it { expect(result.value).to eq("ok") }
    it { expect(result.errors).to eq({}) }
  end

  describe ".failure" do
    context "with a hash" do
      subject(:result) { described_class.failure(scheduled_from: [ "is invalid" ]) }

      it { expect(result).to be_failure }
      it { expect(result.value).to be_nil }
      it { expect(result.errors).to eq({ scheduled_from: [ "is invalid" ] }) }
    end

    context "with ActiveModel::Errors" do
      subject(:result) do
        task = Task.new
        task.validate
        described_class.failure(task.errors)
      end

      it { expect(result).to be_failure }
      it { expect(result.errors).to include(:name, :scheduled_at, :status) }
    end
  end
end
