# frozen_string_literal: true

class Components::Icon < Components::Base
  CUSTOM_GLYPHS = {
    "megaphone-slash" => <<~SVG,
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" fill="currentColor" %<attrs>s>
        <path d="M224,42a8,8,0,0,0-7.94.14L104,112H48A24,24,0,0,0,24,136v8a24,24,0,0,0,24,24H62.2l6.06,29.09A16,16,0,0,0,84,211.64a15.8,15.8,0,0,0,3.37-.36,16,16,0,0,0,12.26-18.94L94.72,168H104l112,69.86A8,8,0,0,0,224,238a8,8,0,0,0,8-8V50A8,8,0,0,0,224,42ZM85.81,196.81,80.22,169H95.09l5.7,27.38A8,8,0,0,1,85.81,196.81ZM40,144v-8a8,8,0,0,1,8-8h56v24H48A8,8,0,0,1,40,144ZM216,219.86,112,153.06V126.94L216,60.14Z"/>
        <line x1="40" y1="24" x2="216" y2="232" stroke="currentColor" stroke-width="16" stroke-linecap="round"/>
      </svg>
    SVG
    "steam" => <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" %<attrs>s>
        <path d="M11.979 0C5.678 0 .511 4.86.022 11.037l6.432 2.658c.545-.371 1.203-.59 1.912-.59.063 0 .125.004.188.006l2.861-4.142V8.91c0-2.495 2.028-4.524 4.524-4.524 2.494 0 4.524 2.031 4.524 4.527s-2.03 4.525-4.524 4.525h-.105l-4.076 2.911c0 .052.004.105.004.159 0 1.875-1.515 3.396-3.39 3.396-1.635 0-3.016-1.173-3.331-2.727L.436 15.27C1.862 20.307 6.486 24 11.979 24c6.627 0 11.999-5.373 11.999-12S18.605 0 11.979 0zM7.54 18.21l-1.473-.61c.262.543.714.999 1.314 1.25 1.297.539 2.793-.076 3.332-1.375.263-.63.264-1.319.005-1.949s-.75-1.121-1.377-1.383c-.624-.26-1.29-.249-1.878-.03l1.523.63c.956.4 1.409 1.5 1.009 2.455-.397.957-1.497 1.41-2.454 1.012H7.54zm11.415-9.303c0-1.662-1.353-3.015-3.015-3.015-1.665 0-3.015 1.353-3.015 3.015 0 1.665 1.35 3.015 3.015 3.015 1.663 0 3.015-1.35 3.015-3.015zm-5.273-.005c0-1.252 1.013-2.266 2.265-2.266 1.249 0 2.266 1.014 2.266 2.266 0 1.251-1.017 2.265-2.266 2.265-1.253 0-2.265-1.014-2.265-2.265z"/>
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
