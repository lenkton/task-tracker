require "rails_helper"

RSpec.describe Task do
  fixtures :statuses, :tasks

  let(:status) { statuses(:todo) }
  let(:base_attributes) do
    {
      name: "Recurring task",
      description: "",
      scheduled_at: 1.day.from_now,
      status:
    }
  end

  describe Task::OneTime do
    subject(:task) { described_class.new(base_attributes.merge(repetition_data: {}, repetition_event_number: 0)) }

    it { expect(task).to be_valid }

    context "with extra repetition data" do
      subject!(:invalid_task) do
        task.repetition_data = { "period" => 1 }
        task.valid?
        task
      end

      it { expect(invalid_task).not_to be_valid }
      it { expect(invalid_task.errors[:repetition_data]).to include("must be empty") }
    end
  end

  describe Task::Daily do
    subject(:task) { described_class.new(base_attributes.merge(repetition_data: { "period" => 2 }, repetition_event_number: 0)) }

    it { expect(task).to be_valid }

    context "without period" do
      subject!(:invalid_task) do
        task.repetition_data = {}
        task.valid?
        task
      end

      it { expect(invalid_task).not_to be_valid }
      it { expect(invalid_task.errors[:repetition_data]).to include("period must be a positive integer") }
    end

    describe "occurrence generation" do
      subject(:occurrences) do
        described_class.new(
          base_attributes.merge(
            repetition_data: { "period" => 2 },
            repetition_event_number: 0,
            scheduled_at: Time.zone.parse("2026-05-20 09:00:00")
          )
        ).generate_occurrences(from, to)
      end

      let(:expected_scheduled_at) do
        [
          "2026-05-24 09:00:00",
          "2026-05-26 09:00:00",
          "2026-05-28 09:00:00"
        ]
        .map { Time.zone.parse(_1) }
      end
      let(:from) { Time.zone.parse("2026-05-24 00:00:00") }
      let(:to) { Time.zone.parse("2026-05-28 23:59:59") }

      it { expect(occurrences.map(&:event_number)).to eq([ 3, 4, 5 ]) }

      it { expect(occurrences.map(&:scheduled_at)).to eq(expected_scheduled_at) }
    end
  end

  describe Task::Monthly do
    subject(:task) { described_class.new(base_attributes.merge(repetition_data: { "day_of_month" => 15 }, repetition_event_number: 0)) }

    it { expect(task).to be_valid }

    context "with invalid day_of_month" do
      subject!(:invalid_task) do
        task.repetition_data = { "day_of_month" => 32 }
        task.valid?
        task
      end

      it { expect(invalid_task).not_to be_valid }
      it { expect(invalid_task.errors[:repetition_data]).to include("day_of_month must be between 1 and 31") }
    end

    describe "occurrence generation" do
      subject(:occurrences) do
        described_class.new(
          base_attributes.merge(
            repetition_data: { "day_of_month" => 15 },
            repetition_event_number: 0,
            scheduled_at: Time.zone.parse("2026-04-15 10:00:00")
          )
        ).generate_occurrences(from, to)
      end

      let(:from) { Time.zone.parse("2026-05-24 00:00:00") }
      let(:to) { Time.zone.parse("2026-07-31 23:59:59") }
      let(:expected_scheduled_at) do
        [
          "2026-06-15 10:00:00",
          "2026-07-15 10:00:00"
        ].map { |value| Time.zone.parse(value) }
      end

      it { expect(occurrences.map(&:event_number)).to eq([ 3, 4 ]) }

      it { expect(occurrences.map(&:scheduled_at)).to eq(expected_scheduled_at) }
    end
  end

  describe Task::OddEven do
    subject(:task) { described_class.new(base_attributes.merge(repetition_data: { "parity" => "even" }, repetition_event_number: 0)) }

    it { expect(task).to be_valid }

    context "with invalid parity" do
      subject!(:invalid_task) do
        task.repetition_data = { "parity" => "sometimes" }
        task.valid?
        task
      end

      it { expect(invalid_task).not_to be_valid }
      it { expect(invalid_task.errors[:repetition_data]).to include("parity must be even or odd") }
    end

    describe "occurrence generation" do
      context "with even parity" do
        subject(:occurrences) do
          described_class.new(
            base_attributes.merge(
              repetition_data: { "parity" => "even" },
              repetition_event_number: 0,
              scheduled_at: Time.zone.parse("2026-05-24 10:00:00")
            )
          ).generate_occurrences(from, to)
        end

        let(:from) { Time.zone.parse("2026-05-24 00:00:00") }
        let(:to) { Time.zone.parse("2026-05-28 23:59:59") }
        let(:expected_scheduled_at) do
          [
            "2026-05-24 10:00:00",
            "2026-05-26 10:00:00",
            "2026-05-28 10:00:00"
          ].map { |value| Time.zone.parse(value) }
        end

        it { expect(occurrences.map(&:event_number)).to eq([ 1, 2, 3 ]) }

        it { expect(occurrences.map(&:scheduled_at)).to eq(expected_scheduled_at) }
      end

      context "with odd parity" do
        subject(:occurrences) do
          described_class.new(
            base_attributes.merge(
              repetition_data: { "parity" => "odd" },
              repetition_event_number: 0,
              scheduled_at: Time.zone.parse("2026-05-25 10:00:00")
            )
          ).generate_occurrences(from, to)
        end

        let(:from) { Time.zone.parse("2026-05-24 00:00:00") }
        let(:to) { Time.zone.parse("2026-05-31 23:59:59") }
        let(:expected_scheduled_at) do
          [
            "2026-05-25 10:00:00",
            "2026-05-27 10:00:00",
            "2026-05-29 10:00:00",
            "2026-05-31 10:00:00"
          ].map { |value| Time.zone.parse(value) }
        end

        it { expect(occurrences.map(&:event_number)).to eq([ 1, 2, 3, 4 ]) }

        it { expect(occurrences.map(&:scheduled_at)).to eq(expected_scheduled_at) }
      end

      context "with odd parity on month boundary (31st and 1st)" do
        subject(:occurrences) do
          described_class.new(
            base_attributes.merge(
              repetition_data: { "parity" => "odd" },
              repetition_event_number: 0,
              scheduled_at: Time.zone.parse("2026-05-31 10:00:00")
            )
          ).generate_occurrences(from, to)
        end

        let(:from) { Time.zone.parse("2026-05-31 00:00:00") }
        let(:to) { Time.zone.parse("2026-06-02 23:59:59") }

        it { expect(occurrences.map(&:event_number)).to eq([ 1, 2 ]) }

        it do
          expect(occurrences.map(&:scheduled_at)).to eq(
            [
              "2026-05-31 10:00:00",
              "2026-06-01 10:00:00"
            ].map { |value| Time.zone.parse(value) }
          )
        end
      end
    end
  end

  describe Task::CustomizedEvent do
    let(:series) { tasks(:daily_standup) }

    subject(:task) do
      described_class.new(
        base_attributes.merge(
          series_task: series,
          repetition_data: {},
          repetition_event_number: 3
        )
      )
    end

    it { expect(task).to be_valid }

    context "without series_task_id" do
      subject!(:invalid_task) do
        task.series_task = nil
        task.valid?
        task
      end

      it { expect(invalid_task).not_to be_valid }
      it { expect(invalid_task.errors[:series_task]).to include("must exist") }
    end

    context "with repetition_data" do
      subject!(:invalid_task) do
        task.repetition_data = { "period" => 1 }
        task.valid?
        task
      end

      it { expect(invalid_task).not_to be_valid }
      it { expect(invalid_task.errors[:repetition_data]).to include("must be empty") }
    end

    context "without repetition_event_number" do
      subject!(:invalid_task) do
        task.repetition_event_number = 0
        task.valid?
        task
      end

      it { expect(invalid_task).not_to be_valid }
      it { expect(invalid_task.errors[:repetition_event_number]).to include("must be greater than 0") }
    end
  end
end
