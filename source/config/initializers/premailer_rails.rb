require_relative '../../lib/mastodon/premailer_webpack_strategy'

Premailer::Rails.config.merge!(remove_ids: true,
                               adapter: :nokogiri,
                               generate_text_part: false,
                               strategies: [PremailerWebpackStrategy],
                               preserve_style_attribute: true)
