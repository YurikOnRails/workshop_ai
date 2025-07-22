# frozen_string_literal: true

module MarkdownHelper
  def render_markdown(text)
    return "" if text.blank?

    renderer = Redcarpet::Render::HTML.new(
      filter_html: true,
      hard_wrap: true,
      link_attributes: { target: "_blank", rel: "noopener noreferrer" }
    )

    markdown = Redcarpet::Markdown.new(renderer, {
      autolink: true,
      no_intra_emphasis: true,
      fenced_code_blocks: true,
      lax_html_blocks: true,
      strikethrough: true,
      superscript: true,
      tables: true,
      underline: true,
      highlight: true,
      quote: true,
      footnotes: true
    })

    # Sanitize the output to prevent XSS
    sanitize(markdown.render(text), tags: %w[p br strong em b i code pre blockquote del ins a ul ol li h1 h2 h3 h4 h5 h6 hr table thead tbody th tr td],
            attributes: %w[href class rel target])
  end

  def simple_format_markdown(text)
    text = h(text)
    text = text.gsub(/\r?\n/, "<br>")
    text = text.gsub(/\*\*(.*?)\*\*/, '<strong>\1</strong>')
    text = text.gsub(/\*(.*?)\*/, '<em>\1</em>')
    text = text.gsub(/`(.*?)`/, '<code>\1</code>')
    text = text.gsub(/\[([^\]]+)\]\(([^)]+)\)/, '<a href="\2" target="_blank" rel="noopener noreferrer">\1</a>')
    text = text.gsub(/^#\s+(.*?)$/, '<h1>\1</h1>')
    text = text.gsub(/^##\s+(.*?)$/, '<h2>\1</h2>')
    text = text.gsub(/^###\s+(.*?)$/, '<h3>\1</h3>')
    text = text.gsub(/^>\s+(.*?)$/, '<blockquote>\1</blockquote>')
    text = text.gsub(/~~(.*?)~~/, '<del>\1</del>')
    text = text.g(/\n\s*\n/, "</p><p>")
    text = "<p>#{text}</p>"
    text.html_safe
  end
end
