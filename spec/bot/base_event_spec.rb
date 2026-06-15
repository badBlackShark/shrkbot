require "rails_helper"

RSpec.describe BaseEvent do
  let(:event) { double("event", bot: double("bot")) }

  def event_class(&body)
    Class.new(described_class) { define_method(:handle, &body) }
  end

  it "runs #handle" do
    ran = false
    klass = event_class { ran = true }
    klass.new(event).call
    expect(ran).to be(true)
  end

  it "rescues errors in #handle, reports to the owner, and returns nil" do
    klass = event_class { raise "boom" }
    expect(OwnerNotifier).to receive(:report).with(hash_including(error: an_instance_of(RuntimeError)))
    expect(klass.new(event).call).to be_nil
  end
end
