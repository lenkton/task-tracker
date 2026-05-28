require "rails_helper"

RSpec.describe Task do
  fixtures :statuses

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
  end

  describe Task::CustomizedEvent do
    subject(:task) { described_class.new(base_attributes.merge(repetition_data: {}, repetition_event_number: 3)) }

    it { expect(task).to be_valid }

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
