# frozen_string_literal: true

class ChannelOptions
  def initialize(server_configuration)
    @config = server_configuration
  end

  def options
    channels.group_by(&:parent_id).flat_map do |parent_id, group|
      grouped(categories[parent_id], group)
    end
  end

  private

  def grouped(category, group)
    return group.map { |channel| option_for(channel) } unless category

    Components::TomSelect::Group.for(
      label: category.name,
      options: group.map { |channel| option_for(channel) }
    )
  end

  def option_for(channel)
    Components::TomSelect::Option.for(value: channel.discord_id, label: channel.name)
  end

  def channels
    @config.server_channels.text.in_discord_order
  end

  def categories
    @categories ||= @config.server_channels.where(channel_type: ServerChannel::CATEGORY_TYPE).index_by(&:discord_id)
  end
end
