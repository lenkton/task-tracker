require "rails_helper"

RSpec.describe Tasks::Write do
  fixtures :tasks, :statuses, :tags

  describe "tags" do
    let(:task) do
      Task.new(
        name: "Tagged task",
        description: "",
        scheduled_at: 1.day.from_now,
        status: statuses(:todo)
      )
    end

    describe "create with existing tag names" do
      subject!(:write_task) { described_class.call(task:, attributes: { tags: [ "отчетность", "операции" ] }) }

      it { expect(write_task).to be_success }
      it { expect(write_task.value.tags.map(&:name)).to contain_exactly("отчетность", "операции") }
    end

    describe "create with unknown tag name" do
      it "creates the tag" do
        expect {
          described_class.call(task:, attributes: { tags: [ "новый тег" ] })
        }.to change(Tag, :count).by(1)
      end

      context "when submitted" do
        before { described_class.call(task:, attributes: { tags: [ "новый тег" ] }) }

        it { expect(Tag.find_by(name: "новый тег")).to be_present }
      end
    end

    describe "update tags" do
      let(:existing_task) { tasks(:one) }

      context "when fewer tags are sent" do
        subject!(:write_task) { described_class.call(task: existing_task, attributes: { tags: [ "звонок" ] }) }

        it { expect(write_task).to be_success }
        it { expect(write_task.value.tags.map(&:name)).to eq([ "звонок" ]) }
        it { expect(write_task.value.tags.map(&:name)).not_to include("отчетность") }
        it { expect(write_task.value.tags.map(&:name)).not_to include("операции") }
      end

      context "when tags are cleared" do
        subject!(:write_task) { described_class.call(task: existing_task, attributes: { tags: [] }) }

        it { expect(write_task).to be_success }
        it { expect(write_task.value.tags).to be_empty }
      end
    end
  end
end
