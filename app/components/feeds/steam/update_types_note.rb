# frozen_string_literal: true

class Components::Feeds::Steam::UpdateTypesNote < Components::Base
  UPDATE_TYPES = %w[
    Integrations::Steam::PatchNotesPublished
    Integrations::Steam::AnnouncementPublished
  ].freeze

  def initialize(subscription:)
    @subscription = subscription
  end

  def view_template
    render Components::LiveWarning.new(
      fields: UPDATE_TYPES.map { |event_type| Components::Feeds::EventTypeSetting.toggle_name(event_type) },
      rule: "exactly-one",
      shown: one_update_type_followed?
    ) { t(".text") }
  end

  private

  def one_update_type_followed?
    @subscription.subscribed_events
      .reject(&:marked_for_destruction?)
      .map(&:event_type)
      .intersection(UPDATE_TYPES)
      .one?
  end
end
