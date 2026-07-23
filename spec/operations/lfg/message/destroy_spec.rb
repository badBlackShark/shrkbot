# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Lfg::Message::Destroy do
  subject(:result) { described_class.call(message:) }

  let!(:message) { create(:lfg_message) }

  it "destroys the row" do
    result

    expect(Lfg::Message.find_by(id: message.id)).to be_nil
  end

  it "returns success" do
    expect(result).to be_success
  end
end
