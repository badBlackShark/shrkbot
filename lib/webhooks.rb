require 'discordrb/webhooks'

class Webhooks

  # Channel => Webhooks::Client
  @clients = {}

  WH_NAME = 'github.com/badBlackShark/shrkbot'.freeze

  def initialize
    # It thinks @clients is nil without this for some reason.
    @clients = {}

    SHRK.servers.each_value do |server|
      server.text_channels.each do |channel|
        channel.webhooks.each do |webhook|
          if webhook.name.eql?(WH_NAME)
            create_client(channel.id, webhook.id, webhook.token)
            break
          end
        end
        create_webhook(channel.id) unless @clients[channel.id]
      end
    end
  end

  # Returns RestClient::Response
  def create_webhook(channel_id)
    webhook = JSON.parse(Discordrb::API::Channel.create_webhook(
      SHRK.token,
      channel_id,
      WH_NAME
    ))
    create_client(channel_id ,webhook['id'], webhook['token'])
  end

  def create_client(channel_id, id, token)
    @clients[channel_id] = Discordrb::Webhooks::Client.new(
      id: id,
      token: token
    )
  end

  def delete_webhooks(channel)
    channel.webhooks.select { |w| w.name.eql?(WH_NAME) }.each(&:delete)
    @clients[channel.id] = nil
  end

  def send(channel_id, content, username: 'shrkbot', avatar_url: SHRK.profile.avatar_url, embed: nil)
    @clients[channel_id].execute(nil, true) do |builder|
      builder.content = content
      builder.username = username
      builder.avatar_url = avatar_url
      # It doesn't work if it's not exactly like this. Don't ask me why.
      builder.add_embed embed do end if embed
    end
  end
end
