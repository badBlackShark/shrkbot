# frozen_string_literal: true

module Roles
  module ActivityEntry
    module_function

    def build(set:, actor:, gained:, lost:)
      {
        title: I18n.t("activity_log.roles.title", locale: :en, raise: true),
        body: body(actor, gained, lost),
        meta: I18n.t("activity_log.roles.source", set: set.name, locale: :en, raise: true)
      }
    end

    def body(actor, gained, lost)
      if gained.any? && lost.any?
        I18n.t("activity_log.roles.role_gained_and_lost", actor:, gained: sentence(gained), lost: sentence(lost), locale: :en, raise: true)
      elsif gained.any?
        I18n.t("activity_log.roles.role_gained", actor:, roles: sentence(gained), locale: :en, raise: true)
      else
        I18n.t("activity_log.roles.role_lost", actor:, roles: sentence(lost), locale: :en, raise: true)
      end
    end

    def sentence(names)
      names.map { |name| "**#{name}**" }.to_sentence
    end

    private_class_method :body, :sentence
  end
end
