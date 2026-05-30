require "rails_helper"

RSpec.describe Tasks::CustomizeOccurrence do
  fixtures :tasks, :statuses, :tags, :tags_tasks, :users

  let(:series) { tasks(:daily_standup) }

  describe ".call" do
    context "when creating a customized occurrence" do
      subject(:result) do
        described_class.call(
          series:,
          attributes: { repetition_event_number: 4, name: "Standup moved" }
        )
      end

      it { expect(result).to be_success }
      it { expect(result.value).to be_a(Task::CustomizedEvent) }
      it { expect(result.value.name).to eq("Standup moved") }
      it { expect(result.value.repetition_event_number).to eq(4) }
      it { expect(result.value.series_task_id).to eq(series.id) }
      it { expect(result.value.repetition_data).to eq({}) }
      it { expect(result.value.scheduled_at).to eq(Time.zone.parse("2026-05-26 09:00:00")) }

      it "creates a customized event record" do
        expect { result }.to change(Task::CustomizedEvent, :count).by(1)
      end
    end

    context "when updating an existing customized occurrence" do
      subject(:result) do
        described_class.call(
          series:,
          attributes: { repetition_event_number: 4, name: "Standup rescheduled", status: "in_progress" }
        )
      end

      let!(:customized) do
        described_class.call(
          series:,
          attributes: { repetition_event_number: 4, name: "Standup moved" }
        ).value
      end


      it { expect(result).to be_success }
      it { expect(result.value.id).to eq(customized.id) }

      it "does not create another customized event" do
        expect { result }.not_to change(Task::CustomizedEvent, :count)
      end

      it { expect(result.value.name).to eq("Standup rescheduled") }
      it { expect(result.value.status.name).to eq("in_progress") }
    end

    context "when series is not recurring" do
      subject(:result) do
        described_class.call(
          series: tasks(:one),
          attributes: { repetition_event_number: 1, name: "Nope" }
        )
      end

      it { expect(result).to be_failure }
      it { expect(result.errors).to eq({ series: [ "must be a recurring task" ] }) }
    end

    context "when repetition_event_number is missing" do
      subject(:result) { described_class.call(series:, attributes: { name: "Nope" }) }

      it { expect(result).to be_failure }
      it { expect(result.errors).to eq({ repetition_event_number: [ "must be a positive integer" ] }) }
    end

    context "when repetition_event_number does not exist for the series" do
      subject(:result) do
        described_class.call(
          series:,
          attributes: { repetition_event_number: 2, name: "Nope" }
        )
      end

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


      it { expect(result).to be_failure }
      it { expect(result.errors).to eq({ repetition_event_number: [ "does not exist for this series" ] }) }
    end

    context "when the occurrence was deleted" do
      subject(:result) do
        described_class.call(
          series:,
          attributes: { repetition_event_number: 4, name: "Nope" }
        )
      end

      before do
        Tasks::Delete.call(task: series, event_number: 4)
      end


      it { expect(result).to be_failure }
      it { expect(result.errors).to eq({ repetition_event_number: [ "does not exist for this series" ] }) }
    end
  end
end
