require "rails_helper"

RSpec.describe Tasks::Filter do
  fixtures :tasks, :statuses

  describe ".call" do
    it "filters by status name" do
      result = described_class.call(scope: Task.all, filters: { statuses: "todo" })

      expect(result.value.map(&:name)).to eq([ "Review pull requests" ])
    end

    it "filters by multiple status names" do
      result = described_class.call(scope: Task.all, filters: { statuses: "todo,in_progress" })

      expect(result.value.map(&:name)).to contain_exactly("Review pull requests", "Implement task tracker API")
    end

    it "filters by scheduled_from" do
      result = described_class.call(scope: Task.all, filters: { scheduled_from: "2026-05-25" })

      expect(result.value.map(&:name)).to eq([ "Implement task tracker API" ])
    end

    it "filters by scheduled_to" do
      result = described_class.call(scope: Task.all, filters: { scheduled_to: "2026-05-24" })

      expect(result.value.map(&:name)).to eq([ "Review pull requests" ])
    end

    it "filters by statuses and scheduled_to" do
      result = described_class.call(
        scope: Task.all,
        filters: { statuses: "todo", scheduled_to: "2026-05-24" }
      )

      expect(result.value.map(&:name)).to eq([ "Review pull requests" ])
    end

    it "filters by statuses and scheduled_from" do
      result = described_class.call(
        scope: Task.all,
        filters: { statuses: "in_progress", scheduled_from: "2026-05-25" }
      )

      expect(result.value.map(&:name)).to eq([ "Implement task tracker API" ])
    end

    context "with invalid scheduled_from" do
      subject(:result) { described_class.call(scope: Task.all, filters: { scheduled_from: "not-a-date" }) }

      it { expect(result).to be_failure }
      it { expect(result.errors).to eq({ scheduled_from: [ "is invalid" ] }) }
    end
  end
end
