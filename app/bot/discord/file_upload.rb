# frozen_string_literal: true

module Discord
  class FileUpload < StringIO
    def initialize(bytes, filename)
      super(bytes)
      @filename = filename
    end

    def path
      @filename
    end

    def original_filename
      @filename
    end
  end
end
