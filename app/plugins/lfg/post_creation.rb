# frozen_string_literal: true

module Lfg
  class PostCreation
    Outcome = Data.define(:ok, :message) do
      def ok?
        ok
      end
    end

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(server_configuration:, channel:, bot:, member:, role_id:, message:, starting_in:, mention_permission:, now: Time.current)
      @server_configuration = server_configuration
      @channel = channel
      @bot = bot
      @member = member
      @role_id = role_id
      @message = message.presence
      @starting_in = starting_in
      @mention_permission = mention_permission
      @now = now
    end

    def call
      return denial(:role_not_configured) unless pingable_role
      return denial(:no_permission) if @mention_permission == false

      start = resolve_start_ts
      return ephemeral(:bad_duration) unless start

      verdict = policy(start).result
      return denial(verdict.reason, detail: verdict.detail) if verdict.denied?

      publish(start)
      success
    end

    private

    def settings
      @settings ||= @server_configuration.lfg_settings
    end

    def pingable_role
      return @pingable_role if defined?(@pingable_role)

      @pingable_role = settings.pingable_roles.find_by(role_id: @role_id)
    end

    def resolve_start_ts
      return @now.to_i if @starting_in.blank?

      span = Duration.parse(@starting_in)
      return nil if span.nil? || span < 1.minute || span > 30.days

      (@now + span).to_i
    end

    def policy(start)
      Lfg::Policy.new(
        effective: Lfg::EffectivePolicy.new(settings, pingable_role),
        channel_id: @channel.id,
        member_role_ids: @member.roles.map(&:id),
        member_joined_at: @member.joined_at,
        cooldown_remaining: cooldown.remaining(guild_id:, user_id: actor_id, at: @now),
        now: @now
      )
    end

    def publish(start)
      message_id = send_post(start)
      Ops::Lfg::Message::Post.call(
        server_configuration: @server_configuration,
        channel_id: @channel.id,
        message_id:
      )
      cooldown.start(guild_id:, user_id: actor_id, at: @now, ttl: settings.cooldown_seconds)
      schedule_jobs(start, message_id)
    end

    def send_post(start)
      container = Lfg::PostMessage.render(
        role_id: @role_id,
        creator_id: actor_id,
        start_ts: start,
        message: @message,
        joiner_ids: [],
        started: started?(start)
      )
      Bot::Discord::Components.send_to(
        @channel,
        container,
        allowed_mentions: {parse: [], roles: [@role_id]},
        subject: subject
      ).id
    end

    def subject
      "<@&#{@role_id}> — <@#{actor_id}> is looking for people to play. Join the Looking for Game post below."
    end

    def actor_id
      @member.id
    end

    def schedule_jobs(start, message_id)
      Lfg::StartJob.set(wait_until: Time.at(start)).perform_later(@channel.id, message_id) unless started?(start)
      Lfg::ExpiryJob.set(wait_until: Time.at(start) + settings.post_lifetime_minutes.minutes).perform_later(@channel.id, message_id)
    end

    def started?(start)
      @now.to_i >= start
    end

    def cooldown
      Lfg::Cooldown.instance
    end

    def guild_id
      @server_configuration.discord_id
    end

    def denial(reason, detail: nil)
      log_denial(reason, detail)
      ephemeral(reason, detail)
    end

    def ephemeral(reason, detail = nil)
      Outcome.new(ok: false, message: "⚠️ #{Lfg::Denial.reason_text(reason, detail)}")
    end

    def success
      Outcome.new(ok: true, message: "Your Looking for Game post is up.")
    end

    def log_denial(reason, detail)
      return unless Bot::ActivityLog.enabled?(@server_configuration, "lfg.denied")

      Bot::ActivityLog.post(
        @server_configuration,
        bot: @bot,
        **Lfg::Denial.entry(reason:, detail:, actor_id:, role_id: @role_id, channel_name: @channel.name)
      )
    end
  end
end
