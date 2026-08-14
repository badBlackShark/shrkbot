# frozen_string_literal: true

class PreviewData
  PATH = Rails.root.join("config/preview_data.yml")

  class << self
    def guild
      data[:guild]
    end

    def user
      data[:user]
    end

    def demo_guild
      @demo_guild ||= Bot::Discord::Guild.new(
        id: guild[:discord_id],
        name: guild[:name],
        owner: true,
        permissions: 0,
        icon: guild[:icon_hash],
        member_count: guild[:member_count]
      )
    end

    def channels
      @channels ||= data[:channels].map { |channel| channel_attributes(channel) }
    end

    def roles
      @roles ||= data[:roles].map { |role| role_attributes(role) }
    end

    def plugins
      data[:plugins]
    end

    private

    def data
      @data ||= YAML.load_file(PATH, symbolize_names: true)
    end

    def channel_attributes(channel)
      channel.merge(channel_type: channel_type_for(channel), overwrites: [])
    end

    def channel_type_for(channel)
      channel[:category] ? ServerChannel::CATEGORY_TYPE : ServerChannel::TEXT_TYPE
    end

    def role_attributes(role)
      {managed: false}.merge(role)
    end
  end
end
