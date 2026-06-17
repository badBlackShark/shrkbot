require "rails_helper"

RSpec.describe ServerSetup do
  subject(:handle) { described_class.new(event).handle }

  let(:event) { double("event", server: double(id: 77)) }

  it "ensures a configuration exists for the server" do
    expect(Ops::ServerConfiguration::Ensure).to receive(:call).with(discord_id: 77)
    handle
  end
end
