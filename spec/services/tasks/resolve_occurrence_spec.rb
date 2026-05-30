require "rails_helper"

RSpec.describe Tasks::ResolveOccurrence do
  fixtures :tasks, :statuses, :users

  describe ".call" do
    let(:series) { tasks(:daily_standup) }

    context "when a generated occurrence exists" do
      subject(:result) { described_class.call(series:, event_number: 4) }

      it { expect(result).to be_success }
      it { expect(result.value).to be_a(Tasks::Occurrence) }
      it { expect(result.value.event_number).to eq(4) }
      it { expect(result.value.scheduled_at).to eq(Time.zone.parse("2026-05-26 09:00:00")) }
    end

    context "when a customized occurrence exists" do
      subject(:result) { described_class.call(series:, event_number: 4) }

      before do
        Tasks::CustomizeOccurrence.call(
          series:,
          attributes: { repetition_event_number: 4, name: "Custom standup" }
        )
      end


      it { expect(result).to be_success }
      it { expect(result.value).to be_a(Task::CustomizedEvent) }
      it { expect(result.value.name).to eq("Custom standup") }
    end

    context "when the event number does not exist" do
      subject(:result) { described_class.call(series:, event_number: 2) }

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

    context "when the task is not recurring" do
      subject(:result) { described_class.call(series: tasks(:one), event_number: 1) }

      it { expect(result).to be_failure }
      it { expect(result.errors).to eq({ repetition_event_number: [ "does not exist for this series" ] }) }
    end
  end
end
