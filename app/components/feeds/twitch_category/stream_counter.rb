# frozen_string_literal: true

class Components::Feeds::TwitchCategory::StreamCounter < Components::Base
  def initialize(server_configuration:, category_id:)
    @config = server_configuration
    @category_id = category_id
  end

  def view_template
    p(class: "text-sm font-medium text-text-primary", aria_live: "polite", data:) do
      t(".counting")
    end
  end

  private

  def data
    {
      controller: "category-counter",
      category_counter_url_value: server_twitch_category_streams_path(@config.discord_id, @category_id),
      category_counter_none_value: t(".none"),
      category_counter_one_value: t(".one"),
      category_counter_many_value: t(".many", number: "{number}"),
      category_counter_failed_value: t(".failed")
    }
  end
end
