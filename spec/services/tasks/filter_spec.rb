require "rails_helper"

RSpec.describe Tasks::Filter do
  fixtures :tasks, :statuses

  let(:interval) { { scheduled_from: "2026-05-24", scheduled_to: "2026-05-28" } }

  describe ".call" do
    it "returns one-time tasks within the interval" do
      result = described_class.call(scope: Task.all, filters: interval)

      expect(result.value.map { |occurrence| occurrence.task.name })
        .to include("Review pull requests", "Implement task tracker API")
    end

    context "when expanding recurring tasks" do
      subject(:standup_occurrences) do
        described_class.call(scope: Task.all, filters: interval).value.select { |occurrence| occurrence.task.name == "Daily standup" }
      end

      it { expect(standup_occurrences.map(&:event_number)).to eq([ 3, 4, 5 ]) }
      it { expect(standup_occurrences.map(&:scheduled_at).map(&:to_date)).to eq([ Date.new(2026, 5, 24), Date.new(2026, 5, 26), Date.new(2026, 5, 28) ]) }
    end

    context "when a recurring occurrence was customized" do
      let(:series) { tasks(:daily_standup) }

      before do
        Tasks::CustomizeOccurrence.call(
          series:,
          attributes: {
            repetition_event_number: 4,
            name: "Custom standup",
            scheduled_at: "2026-05-26T10:30:00Z"
          }
        )
      end

      subject(:result) { described_class.call(scope: Task.all, filters: interval) }

      it "returns the customized event with its series event number" do
        customized = result.value.find { |occurrence| occurrence.task.name == "Custom standup" }

        expect(customized.event_number).to eq(4)
        expect(customized.scheduled_at).to eq(Time.zone.parse("2026-05-26 10:30:00"))
      end

      it "skips the generated occurrence with the same event number" do
        standup_occurrences = result.value.select { |occurrence| occurrence.task.is_a?(Task::Daily) }

        expect(standup_occurrences.map(&:event_number)).to eq([ 3, 5 ])
      end
    end

    context "with status filter" do
      subject(:result) { described_class.call(scope: Task.all, filters: interval.merge(statuses: "todo")) }

      it { expect(result.value.map { |occurrence| occurrence.task.name }).to contain_exactly("Review pull requests", "Daily standup", "Daily standup", "Daily standup") }
    end

    context "with multiple statuses filter" do
      subject(:result) { described_class.call(scope: Task.all, filters: interval.merge(statuses: "todo,in_progress")) }

      it { expect(result.value.map { |occurrence| occurrence.task.name }).to include("Review pull requests", "Implement task tracker API", "Daily standup") }
    end

    context "when scheduled_from is missing" do
      subject(:result) { described_class.call(scope: Task.all, filters: { scheduled_to: "2026-05-28" }) }

      it { expect(result).to be_failure }
      it { expect(result.errors).to eq({ scheduled_from: [ "can't be blank" ] }) }
    end

    context "when scheduled_to is missing" do
      subject(:result) { described_class.call(scope: Task.all, filters: { scheduled_from: "2026-05-24" }) }

      it { expect(result).to be_failure }
      it { expect(result.errors).to eq({ scheduled_to: [ "can't be blank" ] }) }
    end

    context "when scheduled_from is after scheduled_to" do
      subject(:result) do
        described_class.call(
          scope: Task.all,
          filters: { scheduled_from: "2026-05-28", scheduled_to: "2026-05-24" }
        )
      end

      it { expect(result).to be_failure }
      it { expect(result.errors).to eq({ scheduled_to: [ "must be on or after scheduled_from" ] }) }
    end

    context "with invalid scheduled_from" do
      subject(:result) do
        described_class.call(
          scope: Task.all,
          filters: { scheduled_from: "not-a-date", scheduled_to: "2026-05-28" }
        )
      end

      it { expect(result).to be_failure }
      it { expect(result.errors).to eq({ scheduled_from: [ "is invalid" ] }) }
    end
  end
end
