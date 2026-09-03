require "cgi"

SOURCE_PATH = File.join(__dir__, "docs", "privacy-policy.md")
OUTPUT_PATH = File.join(__dir__, "docs", "index.html")

def inline_html(text)
  escaped = CGI.escapeHTML(text)
  escaped = escaped.gsub(/\[([^\]]+)\]\(([^)]+)\)/) do
    label = Regexp.last_match(1)
    href = Regexp.last_match(2)
    %(<a href="#{href}">#{label}</a>)
  end
  escaped.gsub(/`([^`]+)`/, '<code>\1</code>')
end

def heading_id(text, fallback_index)
  number = text[/\A(\d+(?:\.\d+)*)\.?\s/, 1]
  number ? "section-#{number.tr('.', '-')}" : "section-#{fallback_index}"
end

lines = File.readlines(SOURCE_PATH, chomp: true)
body = []
navigation = []
paragraph = []
list_type = nil
table_lines = []
heading_index = 0

flush_paragraph = lambda do
  unless paragraph.empty?
    body << "<p>#{inline_html(paragraph.join(' '))}</p>"
    paragraph.clear
  end
end

flush_list = lambda do
  if list_type
    body << "</#{list_type}>"
    list_type = nil
  end
end

flush_table = lambda do
  unless table_lines.empty?
    rows = table_lines.map { |line| line.strip.sub(/^\|/, "").sub(/\|$/, "").split("|").map(&:strip) }
    header = rows.first
    data_rows = rows.drop(2)
    body << '<div class="table-scroll"><table>'
    body << "<thead><tr>#{header.map { |cell| "<th>#{inline_html(cell)}</th>" }.join}</tr></thead>"
    body << '<tbody>'
    data_rows.each do |row|
      body << "<tr>#{row.map { |cell| "<td>#{inline_html(cell)}</td>" }.join}</tr>"
    end
    body << '</tbody></table></div>'
    table_lines.clear
  end
end

lines.each do |line|
  if line.start_with?("|")
    flush_paragraph.call
    flush_list.call
    table_lines << line
    next
  end

  flush_table.call

  if line.empty?
    flush_paragraph.call
    flush_list.call
    next
  end

  if (match = line.match(/\A(#+)\s+(.+)\z/)) && match[1].length <= 3
    flush_paragraph.call
    flush_list.call
    level = match[1].length
    text = match[2]
    heading_index += 1
    id = level == 1 ? "top" : heading_id(text, heading_index)
    navigation << [text, id] if level == 2
    body << "<h#{level} id=\"#{id}\">#{inline_html(text)}</h#{level}>"
    next
  end

  if (match = line.match(/\A-\s+(.+)\z/))
    flush_paragraph.call
    if list_type != "ul"
      flush_list.call
      list_type = "ul"
      body << "<ul>"
    end
    body << "<li>#{inline_html(match[1])}</li>"
    next
  end

  if (match = line.match(/\A\d+\.\s+(.+)\z/))
    flush_paragraph.call
    if list_type != "ol"
      flush_list.call
      list_type = "ol"
      body << "<ol>"
    end
    body << "<li>#{inline_html(match[1])}</li>"
    next
  end

  paragraph << line
end

flush_paragraph.call
flush_list.call
flush_table.call

nav_html = navigation.map do |text, id|
  %(<li><a href="##{id}">#{inline_html(text.sub(/\A\d+\.\s*/, ""))}</a></li>)
end.join("\n")

document = <<~HTML
  <!doctype html>
  <html lang="ko">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="AICO 애플리케이션 개인정보처리방침">
    <meta name="color-scheme" content="light">
    <title>AICO 개인정보처리방침</title>
    <style>
      :root {
        --background: #fffaf6;
        --surface: #ffffff;
        --text: #292521;
        --muted: #746b64;
        --line: #eadfd6;
        --brand: #e8642a;
        --brand-soft: #fff0e7;
        --focus: #155eef;
      }

      * { box-sizing: border-box; }
      html { scroll-behavior: smooth; }
      body {
        margin: 0;
        background: var(--background);
        color: var(--text);
        font-family: -apple-system, BlinkMacSystemFont, "Apple SD Gothic Neo", "Pretendard", "Noto Sans KR", sans-serif;
        font-size: 16px;
        line-height: 1.75;
        word-break: keep-all;
        overflow-wrap: anywhere;
      }

      a { color: #b84013; text-underline-offset: 3px; }
      a:hover { color: var(--brand); }
      a:focus-visible {
        outline: 3px solid var(--focus);
        outline-offset: 3px;
        border-radius: 3px;
      }

      .skip-link {
        position: fixed;
        top: 12px;
        left: 12px;
        z-index: 10;
        padding: 10px 14px;
        border-radius: 8px;
        background: var(--text);
        color: #fff;
        transform: translateY(-160%);
      }
      .skip-link:focus { transform: translateY(0); }

      .page {
        width: min(100% - 32px, 960px);
        margin: 0 auto;
        padding: 48px 0 80px;
      }

      .hero {
        padding: 36px;
        border: 1px solid var(--line);
        border-radius: 28px;
        background: var(--surface);
        box-shadow: 0 12px 36px rgb(80 48 25 / 8%);
      }
      .eyebrow {
        margin: 0 0 8px;
        color: var(--brand);
        font-size: 14px;
        font-weight: 750;
        letter-spacing: .08em;
      }
      .hero h1 {
        margin: 0;
        font-size: clamp(32px, 6vw, 50px);
        line-height: 1.2;
        letter-spacing: -.04em;
      }
      .hero p { margin: 18px 0 0; color: var(--muted); }
      .hero-meta {
        display: flex;
        flex-wrap: wrap;
        gap: 8px;
        margin-top: 22px;
      }
      .hero-meta span {
        padding: 7px 11px;
        border-radius: 999px;
        background: var(--brand-soft);
        color: #8f3513;
        font-size: 14px;
        font-weight: 650;
      }

      .layout {
        display: grid;
        grid-template-columns: 240px minmax(0, 1fr);
        gap: 32px;
        align-items: start;
        margin-top: 32px;
      }
      nav {
        position: sticky;
        top: 20px;
        max-height: calc(100vh - 40px);
        overflow: auto;
        padding: 20px;
        border: 1px solid var(--line);
        border-radius: 20px;
        background: var(--surface);
      }
      nav strong { display: block; margin-bottom: 10px; }
      nav ol { margin: 0; padding-left: 22px; }
      nav li { margin: 5px 0; color: var(--muted); font-size: 14px; }
      nav a { color: inherit; text-decoration: none; }
      nav a:hover { color: var(--brand); text-decoration: underline; }

      article {
        padding: 36px;
        border: 1px solid var(--line);
        border-radius: 24px;
        background: var(--surface);
      }
      article > h1:first-child,
      article > h1:first-child + p,
      article > h1:first-child + p + p,
      article > h1:first-child + p + p + ul { display: none; }
      h2 {
        scroll-margin-top: 24px;
        margin: 54px 0 16px;
        padding-top: 12px;
        border-top: 1px solid var(--line);
        font-size: 25px;
        line-height: 1.35;
        letter-spacing: -.025em;
      }
      h2:first-of-type { margin-top: 0; border-top: 0; padding-top: 0; }
      h3 { margin: 30px 0 12px; font-size: 19px; line-height: 1.45; }
      p { margin: 12px 0; }
      ul, ol { padding-left: 24px; }
      li + li { margin-top: 6px; }
      code {
        padding: 2px 6px;
        border-radius: 6px;
        background: var(--brand-soft);
        font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
        font-size: .9em;
      }

      .table-scroll {
        margin: 18px 0 26px;
        overflow-x: auto;
        border: 1px solid var(--line);
        border-radius: 14px;
      }
      table { width: 100%; border-collapse: collapse; min-width: 600px; }
      th, td {
        padding: 13px 14px;
        border-bottom: 1px solid var(--line);
        text-align: left;
        vertical-align: top;
      }
      th { background: var(--brand-soft); color: #713016; font-size: 14px; }
      tr:last-child td { border-bottom: 0; }

      footer {
        margin-top: 28px;
        color: var(--muted);
        text-align: center;
        font-size: 14px;
      }

      @media (max-width: 760px) {
        .page { width: min(100% - 20px, 720px); padding: 20px 0 48px; }
        .hero, article { padding: 24px 20px; border-radius: 20px; }
        .layout { display: block; margin-top: 20px; }
        nav { position: static; max-height: none; margin-bottom: 20px; }
        h2 { margin-top: 42px; font-size: 22px; }
      }

      @media print {
        body { background: #fff; font-size: 11pt; }
        .page { width: 100%; padding: 0; }
        .hero, article { box-shadow: none; border: 0; padding: 0; }
        .layout { display: block; }
        nav, .skip-link { display: none; }
        h2 { break-after: avoid; }
        .table-scroll { overflow: visible; }
      }
    </style>
  </head>
  <body>
    <a class="skip-link" href="#policy">본문으로 바로가기</a>
    <main class="page">
      <header class="hero">
        <p class="eyebrow">AICO · PRIVACY</p>
        <h1>AICO 개인정보처리방침</h1>
        <p>성인 보호자와 돌봄 제공자를 위한 AICO가 개인정보를 처리하는 방법을 안내합니다.</p>
        <div class="hero-meta" aria-label="문서 정보">
          <span>시행일 2026. 9. 3.</span>
          <span>버전 1.0</span>
          <span>운영자 우상영</span>
        </div>
      </header>

      <div class="layout">
        <nav aria-label="목차">
          <strong>목차</strong>
          <ol>
            #{nav_html}
          </ol>
        </nav>

        <article id="policy">
          #{body.join("\n")}
        </article>
      </div>

      <footer>
        <p>© 2026 AICO · 문의 <a href="mailto:sangyoung2730@naver.com">sangyoung2730@naver.com</a></p>
      </footer>
    </main>
  </body>
  </html>
HTML

File.write(OUTPUT_PATH, document)
