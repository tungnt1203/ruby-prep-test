module ApplicationHelper
  # Minimal markdown renderer for exam content. Escapes HTML first to prevent XSS.
  def simple_exam_markdown(text)
    return "" if text.blank?
    t = ERB::Util.html_escape_once(text.to_s)
    t = t.gsub(/\*\*(.+?)\*\*/m, '<strong>\1</strong>')
    t = t.gsub(/```(ruby)?\n?([\s\S]*?)```/m) do
      lang = Regexp.last_match(1)
      code = Regexp.last_match(2).strip
      if lang == "ruby"
        highlight_ruby_code(code)
      else
        "<pre class=\"exam-code-block my-2 p-3 bg-slate-100 rounded-lg overflow-x-auto text-sm\"><code>#{ERB::Util.html_escape_once(code)}</code></pre>"
      end
    end
    t.html_safe
  end

  # Syntax-highlights Ruby code via Rouge (HTML formatter escapes output by default).
  def highlight_ruby_code(code)
    return "" if code.blank?
    lexer = Rouge::Lexers::Ruby.new
    formatter = Rouge::Formatters::HTML.new
    highlighted = formatter.format(lexer.lex(code.to_s))
    "<pre class=\"exam-code-block exam-code-block--ruby my-2 p-3 rounded-lg overflow-x-auto text-sm\"><code class=\"language-ruby\">#{highlighted}</code></pre>"
  rescue StandardError
    "<pre class=\"exam-code-block my-2 p-3 bg-slate-100 rounded-lg overflow-x-auto text-sm\"><code>#{ERB::Util.html_escape_once(code.to_s)}</code></pre>"
  end
end
