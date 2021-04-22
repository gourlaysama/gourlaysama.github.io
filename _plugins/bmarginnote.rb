module Jekyll
  class BRenderMarginNoteTag < Liquid::Tag

    require "shellwords"

    def initialize(tag_name, text, tokens)
      super
      @text = text.shellsplit
    end

    def render(context)
      site = context.registers[:site]
      converter = site.find_converter_instance(::Jekyll::Converters::Markdown)

      inner = Kramdown::Document.new(@text[1],{remove_span_html_tags:true}).to_html
      inner = converter.convert(inner).gsub(/<\/?p[^>]*>/, "").chomp # remove <p> tags from render output
      "<p class='bnote'><label for='#{@text[0]}' class='margin-toggle'> &#8853;</label><input type='checkbox' id='#{@text[0]}' class='margin-toggle'/><span class='marginnote'>#{inner} </span></p>"
    end
  end
end

Liquid::Template.register_tag('bmarginnote', Jekyll::BRenderMarginNoteTag)

