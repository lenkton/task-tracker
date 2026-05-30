require "rails_helper"

RSpec.describe Tasks::Delete do
  fixtures :tasks, :statuses, :users

  describe ".call" do
    context "when deleting a one-time task" do
      subject(:result) { described_class.call(task: tasks(:one)) }

      it { expect(result).to be_success }
      it { expect(result.value).to be_nil }
      it { expect { result }.not_to change { Task.unscoped.count } }

      it "marks the task as deleted" do
        result

        expect(tasks(:one).class.unscoped.find(tasks(:one).id).status.name).to eq("deleted")
      end
    end

    context "when deleting a recurring occurrence" do
      let(:series) { tasks(:daily_standup) }

      subject(:result) do
        described_class.call(task: series, event_number: 4)
      end

      it { expect(result).to be_success }
      it { expect(result.value).to be_nil }

      it "creates a deleted customized event" do
        result

        customized = Task::CustomizedEvent.occurrence_slot(series.id, 4)

        expect(customized).to be_present
        expect(customized.status.name).to eq("deleted")
      end
    end

    context "when deleting an already customized occurrence" do
      let(:series) { tasks(:daily_standup) }

      before do
        Tasks::CustomizeOccurrence.call(
          series:,
          attributes: { repetition_event_number: 4, name: "Custom standup" }
        )
      end

      subject(:result) { described_class.call(task: series, event_number: 4) }

      it { expect(result).to be_success }
      it { expect { result }.not_to change { Task::CustomizedEvent.unscoped.count } }

      it "marks the customized event as deleted" do
        result

        customized = Task::CustomizedEvent.occurrence_slot(series.id, 4)

        expect(customized.name).to eq("Custom standup")
        expect(customized.status.name).to eq("deleted")
      end
    end

    context "when the occurrence does not exist" do
      let(:series) do
        Task::Monthly.create!(
          name: "Monthly report",
          description: "",
          scheduled_at: Time.zone.parse("2026-01-31 10:00:00"),
          status: statuses(:todo),
          user: users(:one),
          repetition_data: { "day_of_month" => 31 },
          repetition_event_number: 0
        )
      end

      subject(:result) { described_class.call(task: series, event_number: 2) }

      it { expect(result).to be_failure }
      it { expect(result.errors).to eq({ repetition_event_number: [ "does not exist for this series" ] }) }
    end

    context "when the occurrence is already deleted" do
      let(:series) { tasks(:daily_standup) }

      before do
        described_class.call(task: series, event_number: 4)
      end

      subject(:result) { described_class.call(task: series, event_number: 4) }

      it { expect(result).to be_failure }
      it { expect(result.errors).to eq({ repetition_event_number: [ "does not exist for this series" ] }) }
    end
  end
end
