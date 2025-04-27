# frozen_string_literal: true

class URLPlaceholder
  LENGTH = 23

  class << self
    def generate(url)
      # we add 1 here because we are replacing the url and the leading space
      'x' * [url.length, LENGTH + 1].min
    end
  end
end
