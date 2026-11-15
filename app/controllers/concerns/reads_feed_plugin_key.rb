# frozen_string_literal: true

module ReadsFeedPluginKey
  extend ActiveSupport::Concern

  included do
    helper_method :plugin_key
  end

  private

  def plugin_key
    params[:plugin_key].to_sym
  end
end
