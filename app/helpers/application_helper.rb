module ApplicationHelper
  # Minimal markdown renderer for exam content. Decodes any existing HTML entities
  # (e.g. from API) then escapes to prevent XSS and double-encoding.
  def simple_exam_markdown(text)
    return "" if text.blank?
    raw = text.to_s
    # Decode HTML entities (e.g. =&gt; -> =>, &lt; -> <); repeat to handle double-encoding
    loop do
      decoded = CGI.unescape_html(raw)
      break if decoded == raw
      raw = decoded
    end
    # Remove backticks around quoted strings (e.g. `"hello"` -> "hello", `'A'` -> 'A')
    raw = raw.gsub(/`"([^"]*)"`/, '"\1"').gsub(/`'([^']*)'`/, "'\\1'")

    # Process code blocks BEFORE escaping, so code with " and < is not double-encoded
    code_blocks = []
    raw = raw.gsub(/```(ruby)?\n?([\s\S]*?)```/m) do
      lang = Regexp.last_match(1)
      code = Regexp.last_match(2).strip
      html = if lang == "ruby"
        highlight_ruby_code(code)
      else
        "<pre class=\"exam-code-block my-2 p-3 bg-slate-100 rounded-lg overflow-x-auto text-sm\"><code>#{ERB::Util.html_escape_once(code)}</code></pre>"
      end
      code_blocks << html
      "\n\x00CODEBLOCK#{code_blocks.size - 1}\x00\n"
    end

    # Remove inline backticks (e.g. `__init__` -> __init__, `new` -> new); safe after ``` blocks are replaced
    raw = raw.gsub(/`([^`]+)`/, '\1')

    t = ERB::Util.html_escape_once(raw)
    t = t.gsub(/\*\*(.+?)\*\*/m, '<strong>\1</strong>')
    code_blocks.each_with_index { |html, i| t = t.sub("\x00CODEBLOCK#{i}\x00", html) }
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
