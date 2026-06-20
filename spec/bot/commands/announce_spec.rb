require "rails_helper"

RSpec.describe Commands::Announce do
  subject(:execute) { described_class.new(event).execute }

  let(:event) { double("event") }
  let(:modal) { double("modal") }
  let(:row) { double("row") }

  it "opens a paragraph modal for the announcement" do
    expect(event).to receive(:show_modal)
      .with(hash_including(custom_id: described_class::MODAL_ID))
      .and_yield(modal)
    allow(modal).to receive(:label).and_yield(row)
    expect(row).to receive(:text_input)
      .with(hash_including(style: :paragraph, custom_id: described_class::INPUT_ID, required: true))

    execute
  end

  it "is owner-only" do
    expect(described_class.owner_only?).to be(true)
  end
end
