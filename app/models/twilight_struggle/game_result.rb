# frozen_string_literal: true

module TwilightStruggle
  class GameResult
    include ActiveModel::Model
    include ActiveModel::Attributes

    SIDES = %w[usa ussr tie].freeze
    MAX_VIDEO_URLS = 5
    NAME_LIMIT = 100
    FLAG_LIMIT = 8
    METHOD_LIMIT = 60
    CODE_LIMIT = 60

    attribute :usa_player, :string
    attribute :ussr_player, :string
    attribute :usa_flag, :string
    attribute :ussr_flag, :string
    attribute :winning_side, :string
    attribute :winning_method, :string
    attribute :game_code, :string
    attribute :winning_turn, :integer
    attribute :game_date, :datetime
    attribute :reported_at, :datetime
    attribute :video_urls, default: -> { [] }

    validates :usa_player, :ussr_player, presence: true, length: {maximum: NAME_LIMIT}
    validates :usa_flag, :ussr_flag, length: {maximum: FLAG_LIMIT}, allow_blank: true
    validates :winning_side, inclusion: {in: SIDES}
    validates :winning_method, presence: true, length: {maximum: METHOD_LIMIT}
    validates :game_code, length: {maximum: CODE_LIMIT}, allow_blank: true
    validates :winning_turn, numericality: {only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 11}, allow_nil: true
    validates :reported_at, presence: true
    validate :video_urls_must_be_http

    private

    def video_urls_must_be_http
      urls = Array(video_urls)

      if urls.size > MAX_VIDEO_URLS
        errors.add(:video_urls, "has too many URLs")
        return
      end

      urls.each do |url|
        uri = URI.parse(url.to_s)
        errors.add(:video_urls, "must be a valid http(s) URL") unless uri.is_a?(URI::HTTP)
      rescue URI::InvalidURIError
        errors.add(:video_urls, "must be a valid http(s) URL")
      end
    end
  end
end
