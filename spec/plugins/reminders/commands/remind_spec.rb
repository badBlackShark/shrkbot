require "rails_helper"

RSpec.describe Reminders::Remind do
  let(:event) do
    double("event", user: double(id: 1), channel_id: 2, server_id: 3,
      options: {"duration" => "1h", "message" => "hi", "deliver" => "here"}, respond: nil)
  end

  def success_result
    ApplicationOperation::Result.new(true, double(remind_at: Time.at(1_000)), [])
  end

  it "calls CreateReminder with the event's options and confirms" do
    expect(CreateReminder).to receive(:call)
      .with(hash_including(user_id: 1, channel_id: 2, server_id: 3, message: "hi", duration: "1h", deliver_via_dm: false))
      .and_return(success_result)
    expect(event).to receive(:respond).with(hash_including(ephemeral: true, content: a_string_including("remind you")))

    described_class.new(event).execute
  end

  it "maps deliver=dm to deliver_via_dm: true" do
    allow(event).to receive(:options).and_return({"duration" => "1h", "message" => "hi", "deliver" => "dm"})
    expect(CreateReminder).to receive(:call).with(hash_including(deliver_via_dm: true)).and_return(success_result)
    described_class.new(event).execute
  end

  it "surfaces the operation's failure message" do
    allow(CreateReminder).to receive(:call).and_return(ApplicationOperation::Result.new(false, nil, ["bad duration"]))
    expect(event).to receive(:respond).with(hash_including(content: a_string_including("bad duration")))
    described_class.new(event).execute
  end
end
