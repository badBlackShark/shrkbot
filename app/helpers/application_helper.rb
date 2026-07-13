# frozen_string_literal: true

module ApplicationHelper
  def social_meta_tags
    title = content_for(:title).presence || t("meta.default_title")
    description = content_for(:page_description).presence || t("meta.default_description")
    image = image_url("shrkbot-mascot.png")

    safe_join(
      [
        tag.meta(name: "description", content: description),
        tag.meta(property: "og:site_name", content: "shrkbot"),
        tag.meta(property: "og:type", content: "website"),
        tag.meta(property: "og:title", content: title),
        tag.meta(property: "og:description", content: description),
        tag.meta(property: "og:url", content: request.original_url),
        tag.meta(property: "og:image", content: image),
        tag.meta(name: "twitter:card", content: "summary_large_image"),
        tag.meta(name: "twitter:title", content: title),
        tag.meta(name: "twitter:description", content: description),
        tag.meta(name: "twitter:image", content: image)
      ],
      "\n"
    )
  end
end
