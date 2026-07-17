# frozen_string_literal: true

class Components::Icon < Components::Base
  CUSTOM_GLYPHS = {
    "megaphone-slash" => <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" fill="currentColor" %<attrs>s>
        <path d="M224,42a8,8,0,0,0-7.94.14L104,112H48A24,24,0,0,0,24,136v8a24,24,0,0,0,24,24H62.2l6.06,29.09A16,16,0,0,0,84,211.64a15.8,15.8,0,0,0,3.37-.36,16,16,0,0,0,12.26-18.94L94.72,168H104l112,69.86A8,8,0,0,0,224,238a8,8,0,0,0,8-8V50A8,8,0,0,0,224,42ZM85.81,196.81,80.22,169H95.09l5.7,27.38A8,8,0,0,1,85.81,196.81ZM40,144v-8a8,8,0,0,1,8-8h56v24H48A8,8,0,0,1,40,144ZM216,219.86,112,153.06V126.94L216,60.14Z"/>
        <line x1="40" y1="24" x2="216" y2="232" stroke="currentColor" stroke-width="16" stroke-linecap="round"/>
      </svg>
    SVG
  }.freeze

  def initialize(name, weight: :regular, **options)
    @name = name.to_s
    @weight = weight
    @options = options
    @options[:class] ||= "size-5"
  end

  def view_template
    if CUSTOM_GLYPHS.key?(@name)
      raw(safe(custom_glyph))
    else
      raw(safe(PhosphorIcons::Icon.new(@name, style: @weight, **@options).to_svg))
    end
  end

  private

  def custom_glyph
    attrs_str = @options.map { |k, v| "#{k.to_s.tr("_", "-")}=\"#{ERB::Util.html_escape(v)}\"" }.join(" ")
    CUSTOM_GLYPHS[@name] % {attrs: attrs_str}
  end
end
