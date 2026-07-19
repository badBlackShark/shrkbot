# frozen_string_literal: true

module Lfg
  class EffectivePolicy
    def initialize(settings, pingable_role)
      @settings = settings
      @pingable_role = pingable_role
    end

    def min_membership_days
      @pingable_role.min_membership_days || @settings.default_min_membership_days
    end

    def required_role_ids
      override(@pingable_role.required_role_ids, @settings.default_required_role_ids)
    end

    def excluded_role_ids
      override(@pingable_role.excluded_role_ids, @settings.default_excluded_role_ids)
    end

    def allowed_channel_ids
      override(@pingable_role.allowed_channel_ids, @settings.allowed_channel_ids)
    end

    private

    def override(role_value, default)
      role_value.nil? ? default : role_value
    end
  end
end
