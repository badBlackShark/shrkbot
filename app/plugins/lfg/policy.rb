# frozen_string_literal: true

module Lfg
  class Policy
    Result = Data.define(:ok, :reason, :detail) do
      def ok?
        ok
      end

      def denied?
        !ok
      end
    end

    def initialize(effective:, channel_id:, member_role_ids:, member_joined_at:, cooldown_remaining:, now:)
      @effective = effective
      @channel_id = channel_id
      @member_role_ids = member_role_ids
      @member_joined_at = member_joined_at
      @cooldown_remaining = cooldown_remaining
      @now = now
    end

    def result
      return denial(:channel_not_allowed, @effective.allowed_channel_ids) unless channel_allowed?
      return denial(:missing_required_role, @effective.feature_required_role_ids) unless gate_met?(@effective.feature_required_role_ids)
      return denial(:missing_game_role, @effective.role_required_role_ids) unless gate_met?(@effective.role_required_role_ids)
      return denial(:has_excluded_role, blocking_excluded_role_ids) if blocking_excluded_role_ids.any?
      return denial(:too_new, @effective.min_membership_days) unless old_enough?
      return denial(:cooldown, @cooldown_remaining) if @cooldown_remaining.positive?

      Result.new(ok: true, reason: nil, detail: nil)
    end

    private

    def channel_allowed?
      allowed = @effective.allowed_channel_ids
      allowed.empty? || allowed.include?(@channel_id)
    end

    def gate_met?(required)
      required.empty? || required.intersect?(@member_role_ids)
    end

    def blocking_excluded_role_ids
      @blocking_excluded_role_ids ||= @effective.excluded_role_ids & @member_role_ids
    end

    def old_enough?
      days = @effective.min_membership_days
      return true if days.nil?
      return false if @member_joined_at.nil?

      @member_joined_at <= @now - days.days
    end

    def denial(reason, detail = nil)
      Result.new(ok: false, reason:, detail:)
    end
  end
end
