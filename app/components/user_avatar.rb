# frozen_string_literal: true

class Components::UserAvatar < Components::Base
  include Phlex::Rails::Helpers::ImageTag
  include Components::Initials

  SIZES = {
    sm: {box: "size-8", text: "text-xs"},
    lg: {box: "size-16", text: "text-lg"}
  }.freeze

  def initialize(user:, size:)
    @user = user
    @size = size
  end

  def view_template
    if @user.avatar_url
      image_tag(@user.avatar_url, alt: "", loading: "lazy", class: "#{dims[:box]} rounded-full object-cover")
    else
      span(class: "flex #{dims[:box]} items-center justify-center rounded-full bg-accent-soft #{dims[:text]} font-bold text-accent-soft-fg") do
        initials(@user.display_name)
      end
    end
  end

  private

  def dims
    SIZES.fetch(@size)
  end
end
