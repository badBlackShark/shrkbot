# frozen_string_literal: true

class Components::ServerAvatar < Components::Base
  include Components::Initials

  SIZES = {
    xs: {box: "size-5", radius: "rounded-[5px]", text: "text-[9px]"},
    sm: {box: "size-7", radius: "rounded-md", text: "text-xs"},
    md: {box: "size-8", radius: "rounded-md", text: "text-xs"},
    lg: {box: "size-12", radius: "rounded-lg", text: ""},
    xl: {box: "size-14", radius: "rounded-xl", text: "text-xl"}
  }.freeze

  def initialize(server:, size:, tone: :accent, dim: false)
    @server = server
    @size = size
    @tone = tone
    @dim = dim
  end

  def view_template
    if @server.icon_url
      img(src: @server.icon_url, alt: "", loading: "lazy", class: image_class)
    else
      span(class: initials_class) { initials(@server.name.to_s) }
    end
  end

  private

  def dims
    SIZES.fetch(@size)
  end

  def image_class
    "#{dims[:box]} #{dims[:radius]} flex-none object-cover#{dim_suffix}"
  end

  def initials_class
    [dims[:box], dims[:radius], dims[:text], "flex flex-none items-center justify-center", tone_classes, weight]
      .reject(&:empty?)
      .join(" ") + dim_suffix
  end

  def tone_classes
    (@tone == :sunken) ? "bg-surface-sunken text-text-secondary" : "bg-accent-soft text-accent-soft-fg"
  end

  def weight
    (@tone == :sunken) ? "font-semibold" : "font-bold"
  end

  def dim_suffix
    @dim ? " opacity-60" : ""
  end
end
