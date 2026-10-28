# frozen_string_literal: true

class ValidateLanguagesCheckOnFeedSubscriptions < ActiveRecord::Migration[8.1]
  def change
    validate_check_constraint :feed_subscriptions, name: "feed_subscriptions_languages_check"
  end
end
