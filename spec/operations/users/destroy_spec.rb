# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Users::Destroy do
  subject(:result) { described_class.call(user:) }

  let(:user) { create(:user) }
  let!(:reminder) { create(:reminder, user_id: user.discord_id) }
  let!(:other_reminder) { create(:reminder) }

  it "destroys the user" do
    result
    expect(User.exists?(user.id)).to be(false)
  end

  it "deletes reminders whose user_id equals the user's discord_id" do
    result
    expect(Reminders::Reminder.exists?(reminder.id)).to be(false)
  end

  it "leaves other users' reminders untouched" do
    result
    expect(Reminders::Reminder.exists?(other_reminder.id)).to be(true)
  end

  it "returns success" do
    expect(result.success?).to be(true)
  end
end
