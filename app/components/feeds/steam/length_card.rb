# frozen_string_literal: true

class Components::Feeds::Steam::LengthCard < Components::Base
  def initialize(subscription:)
    @subscription = subscription
  end

  def view_template
    render Components::Card.new do
      h2(class: "mb-3 font-semibold") { t(".length_title") }
      render Components::RadioCardGroup.new(
        name: "subscription[body_length]",
        value: @subscription.settings.body_length,
        label: t(".length_title"),
        options: ::Feeds::Steam::Settings::BODY_LENGTHS.map { |length| length_option(length) }
      )
    end
  end

  private

  def length_option(length)
    {value: length, title: t(".length.#{length}.title"), description: t(".length.#{length}.description")}
  end
end
