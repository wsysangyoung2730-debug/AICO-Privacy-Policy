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
effective_date = lines.find { |line| line.start_with?("- 시행일:") }&.sub("- 시행일:", "")&.strip
updated_date = lines.find { |line| line.start_with?("- 최종 수정일:") }&.sub("- 최종 수정일:", "")&.strip
policy_version = lines.find { |line| line.start_with?("- 버전:") }&.sub("- 버전:", "")&.strip

if [effective_date, updated_date, policy_version].any? { |value| value.nil? || value.empty? }
  abort "개인정보처리방침의 시행일, 최종 수정일, 버전을 확인해 주세요."
end

history_lines = lines.drop_while { |line| line != "### 변경 이력" }
latest_history_row = history_lines.find { |line| line.match?(/\A\|\s*\d+(?:\.\d+)*\s*\|/) }
latest_history_cells = latest_history_row&.strip&.sub(/^\|/, "")&.sub(/\|$/, "")&.split("|")&.map(&:strip)

unless latest_history_cells && latest_history_cells[0] == policy_version && latest_history_cells[1] == effective_date
  abort "상단 버전·시행일과 변경 이력의 최신 항목이 일치하지 않습니다."
end

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
    body << '<div class="table-scroll" role="region" aria-label="표를 좌우로 스크롤할 수 있습니다" tabindex="0"><table>'
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
    id = level == 1 ? "policy-title" : heading_id(text, heading_index)
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
    <meta name="description" content="AICO가 개인정보를 수집·이용·보관·공유하는 방법과 이용자의 권리를 안내합니다.">
    <meta name="color-scheme" content="light">
    <meta name="theme-color" content="#ffffff">
    <meta property="og:title" content="AICO 개인정보처리방침">
    <meta property="og:description" content="AICO의 개인정보 처리 방식과 이용자의 권리를 확인하세요.">
    <meta property="og:type" content="website">
    <meta property="og:url" content="https://aico-privacy-policy.vercel.app/">
    <meta property="og:image" content="https://aico-privacy-policy.vercel.app/assets/aico-app-icon.jpg">
    <meta property="og:image:alt" content="AICO 앱 아이콘">
    <link rel="canonical" href="https://aico-privacy-policy.vercel.app/">
    <link rel="icon" type="image/jpeg" href="./assets/aico-app-icon.jpg">
    <title>AICO 개인정보처리방침</title>
    <style>
      :root {
        --background: #ffffff;
        --surface: #f5f5f7;
        --surface-raised: #ffffff;
        --text: #1d1d1f;
        --muted: #6e6e73;
        --subtle: #86868b;
        --line: #d2d2d7;
        --line-soft: #e8e8ed;
        --brand: #f0440a;
        --brand-dark: #c93400;
        --brand-soft: #fff3ee;
        --link: #0066cc;
        --focus: #0071e3;
        --content-width: 1120px;
      }

      * { box-sizing: border-box; }
      html {
        scroll-behavior: smooth;
        scroll-padding-top: 88px;
      }
      body {
        margin: 0;
        background: var(--background);
        color: var(--text);
        font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Apple SD Gothic Neo", "Noto Sans KR", sans-serif;
        font-size: 17px;
        line-height: 1.68;
        letter-spacing: -0.012em;
        word-break: keep-all;
        overflow-wrap: anywhere;
        -webkit-font-smoothing: antialiased;
      }

      a {
        color: var(--link);
        text-decoration-thickness: 1px;
        text-underline-offset: 3px;
      }
      a:hover { color: #004f9f; }
      a:focus-visible {
        outline: 3px solid var(--focus);
        outline-offset: 4px;
        border-radius: 6px;
      }

      .skip-link {
        position: fixed;
        top: 10px;
        left: 16px;
        z-index: 100;
        padding: 10px 16px;
        border-radius: 10px;
        background: var(--text);
        color: #fff;
        transform: translateY(-180%);
        transition: transform 160ms ease;
      }
      .skip-link:focus { transform: translateY(0); }

      .site-header {
        position: sticky;
        top: 0;
        z-index: 20;
        border-bottom: 1px solid rgb(0 0 0 / 9%);
        background: rgb(255 255 255 / 86%);
        -webkit-backdrop-filter: saturate(180%) blur(20px);
        backdrop-filter: saturate(180%) blur(20px);
      }
      .site-header__inner {
        width: min(calc(100% - 48px), var(--content-width));
        min-height: 52px;
        margin: 0 auto;
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 24px;
      }
      .brand {
        display: inline-flex;
        align-items: center;
        gap: 10px;
        color: var(--text);
        font-size: 18px;
        font-weight: 700;
        letter-spacing: -0.025em;
        text-decoration: none;
      }
      .brand__icon {
        width: 30px;
        height: 30px;
        display: block;
        border: 1px solid rgb(0 0 0 / 6%);
        border-radius: 8px;
        object-fit: cover;
        box-shadow: 0 1px 4px rgb(0 0 0 / 10%);
      }
      .site-header__section {
        color: var(--muted);
        font-size: 14px;
        font-weight: 600;
      }

      .page { padding-bottom: 96px; }
      .hero {
        width: min(calc(100% - 48px), var(--content-width));
        margin: 0 auto;
        padding: clamp(72px, 10vw, 132px) 0 72px;
      }
      .eyebrow {
        margin: 0 0 18px;
        color: var(--brand-dark);
        font-size: 15px;
        font-weight: 700;
        letter-spacing: 0.045em;
        text-transform: uppercase;
      }
      .hero__title-row {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: clamp(36px, 6vw, 84px);
      }
      .hero h1 {
        flex: 1 1 auto;
        max-width: 880px;
        margin: 0;
        font-size: clamp(42px, 7vw, 72px);
        font-weight: 700;
        line-height: 1.08;
        letter-spacing: -0.055em;
      }
      .hero__character {
        width: clamp(136px, 16vw, 184px);
        height: auto;
        flex: 0 0 auto;
        display: block;
        filter: drop-shadow(0 18px 22px rgb(191 50 0 / 16%));
      }
      .hero__lead {
        max-width: 760px;
        margin: 30px 0 0;
        color: var(--muted);
        font-size: clamp(20px, 2.6vw, 26px);
        font-weight: 500;
        line-height: 1.48;
        letter-spacing: -0.025em;
      }
      .hero-meta {
        display: flex;
        flex-wrap: wrap;
        gap: 10px 24px;
        margin: 32px 0 0;
        padding: 0;
        list-style: none;
      }
      .hero-meta li {
        color: var(--subtle);
        font-size: 14px;
        font-weight: 600;
      }
      .hero-meta li + li::before {
        margin-right: 24px;
        color: var(--line);
        content: "•";
      }

      .principles {
        border-top: 1px solid var(--line);
        border-bottom: 1px solid var(--line);
        background: var(--surface);
      }
      .principles__inner {
        width: min(calc(100% - 48px), var(--content-width));
        margin: 0 auto;
        display: grid;
        grid-template-columns: repeat(3, 1fr);
      }
      .principle {
        min-height: 164px;
        padding: 36px 34px 34px 0;
      }
      .principle + .principle {
        padding-left: 34px;
        border-left: 1px solid var(--line);
      }
      .principle__number {
        display: block;
        margin-bottom: 18px;
        color: var(--brand-dark);
        font-size: 13px;
        font-weight: 700;
        letter-spacing: 0.06em;
      }
      .principle strong {
        display: block;
        margin-bottom: 8px;
        font-size: 20px;
        line-height: 1.3;
        letter-spacing: -0.025em;
      }
      .principle p {
        margin: 0;
        color: var(--muted);
        font-size: 15px;
        line-height: 1.55;
      }

      .layout {
        width: min(calc(100% - 48px), var(--content-width));
        margin: 0 auto;
        display: grid;
        grid-template-columns: 250px minmax(0, 760px);
        justify-content: space-between;
        gap: 72px;
        align-items: start;
        padding-top: 84px;
      }
      .toc {
        position: sticky;
        top: 80px;
        max-height: calc(100vh - 104px);
        overflow: auto;
        padding-right: 20px;
      }
      .toc strong {
        display: block;
        margin-bottom: 16px;
        font-size: 14px;
        letter-spacing: -0.01em;
      }
      .toc ol {
        margin: 0;
        padding: 0;
        border-left: 1px solid var(--line);
        list-style: none;
      }
      .toc li { margin: 0; }
      .toc a {
        display: block;
        margin-left: -1px;
        padding: 7px 0 7px 18px;
        border-left: 2px solid transparent;
        color: var(--muted);
        font-size: 13px;
        line-height: 1.35;
        text-decoration: none;
      }
      .toc a:hover,
      .toc a[aria-current="true"] {
        border-left-color: var(--brand);
        color: var(--text);
      }

      .mobile-toc {
        display: none;
        margin-bottom: 46px;
        border-top: 1px solid var(--line);
        border-bottom: 1px solid var(--line);
      }
      .mobile-toc summary {
        min-height: 52px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        font-weight: 650;
        cursor: pointer;
      }
      .mobile-toc summary::after {
        color: var(--brand-dark);
        content: "+";
        font-size: 24px;
        font-weight: 400;
      }
      .mobile-toc[open] summary::after { content: "−"; }
      .mobile-toc ol {
        margin: 0;
        padding: 0 0 22px;
        display: grid;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 4px 24px;
        list-style: none;
      }
      .mobile-toc a {
        display: block;
        padding: 8px 0;
        color: var(--muted);
        font-size: 14px;
        text-decoration: none;
      }

      article {
        min-width: 0;
      }
      .policy-body > h1:first-child,
      .policy-body > h1:first-child + p,
      .policy-body > h1:first-child + p + p,
      .policy-body > h1:first-child + p + p + ul { display: none; }
      h2 {
        margin: 80px 0 22px;
        padding-top: 26px;
        border-top: 1px solid var(--line);
        font-size: clamp(28px, 3.3vw, 36px);
        font-weight: 700;
        line-height: 1.22;
        letter-spacing: -0.04em;
      }
      h2:first-of-type { margin-top: 0; border-top: 0; padding-top: 0; }
      h3 {
        margin: 42px 0 14px;
        font-size: 21px;
        line-height: 1.4;
        letter-spacing: -0.025em;
      }
      p { margin: 14px 0; }
      article ul,
      article ol { padding-left: 25px; }
      article li + li { margin-top: 8px; }
      code {
        padding: 2px 5px;
        border-radius: 5px;
        background: var(--surface);
        font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
        font-size: 0.9em;
      }

      .table-scroll {
        margin: 24px 0 34px;
        overflow-x: auto;
        border-top: 1px solid var(--text);
        border-bottom: 1px solid var(--line);
        overscroll-behavior-inline: contain;
      }
      .table-scroll:focus-visible {
        outline: 3px solid var(--focus);
        outline-offset: 3px;
      }
      table {
        width: 100%;
        min-width: 640px;
        border-collapse: collapse;
        font-size: 15px;
        line-height: 1.52;
      }
      th, td {
        padding: 16px 14px;
        border-bottom: 1px solid var(--line-soft);
        text-align: left;
        vertical-align: top;
      }
      th {
        background: var(--surface);
        color: var(--text);
        font-size: 13px;
        font-weight: 700;
      }
      tr:last-child td { border-bottom: 0; }

      footer {
        margin-top: 100px;
        border-top: 1px solid var(--line);
        background: var(--surface);
      }
      .footer__inner {
        width: min(calc(100% - 48px), var(--content-width));
        min-height: 112px;
        margin: 0 auto;
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 24px;
        color: var(--muted);
        font-size: 13px;
      }
      .footer__inner p { margin: 0; }
      .back-to-top {
        min-height: 44px;
        display: inline-flex;
        align-items: center;
        color: var(--muted);
        font-weight: 600;
        text-decoration: none;
      }

      @media (max-width: 860px) {
        .site-header__inner,
        .hero,
        .principles__inner,
        .layout,
        .footer__inner { width: min(calc(100% - 40px), 720px); }
        .hero { padding: 76px 0 56px; }
        .hero__title-row { gap: 28px; }
        .hero__character { width: 124px; }
        .principles__inner { grid-template-columns: 1fr; }
        .principle {
          min-height: auto;
          padding: 28px 0;
        }
        .principle + .principle {
          padding-left: 0;
          border-top: 1px solid var(--line);
          border-left: 0;
        }
        .layout {
          display: block;
          padding-top: 58px;
        }
        .toc { display: none; }
        .mobile-toc { display: block; }
        h2 { margin-top: 64px; }
      }

      @media (max-width: 620px) {
        .hero__character { display: none; }
      }

      @media (max-width: 520px) {
        body { font-size: 16px; line-height: 1.7; }
        .site-header__inner,
        .hero,
        .principles__inner,
        .layout,
        .footer__inner { width: min(calc(100% - 32px), 720px); }
        .site-header__section { display: none; }
        .hero { padding: 58px 0 46px; }
        .hero h1 { font-size: 42px; }
        .hero__lead { margin-top: 22px; font-size: 19px; }
        .hero-meta { display: grid; gap: 4px; margin-top: 24px; }
        .hero-meta li + li::before { display: none; }
        .mobile-toc ol { grid-template-columns: 1fr; }
        h2 { margin-top: 56px; font-size: 28px; }
        h3 { margin-top: 34px; font-size: 20px; }
        .footer__inner {
          min-height: 132px;
          align-items: flex-start;
          flex-direction: column;
          justify-content: center;
          gap: 4px;
        }
      }

      @media (prefers-reduced-motion: reduce) {
        html { scroll-behavior: auto; }
        *, *::before, *::after {
          scroll-behavior: auto !important;
          transition-duration: 0.01ms !important;
        }
      }

      @media print {
        body { font-size: 10.5pt; }
        .site-header, .principles, .toc, .mobile-toc, .skip-link, .back-to-top, .hero__character { display: none; }
        .hero, .layout { width: 100%; padding: 0; }
        .hero { margin-bottom: 36px; }
        .hero h1 { font-size: 30pt; }
        .hero__lead { font-size: 14pt; }
        .layout { display: block; }
        footer { margin-top: 48px; background: #fff; }
        .footer__inner { width: 100%; min-height: auto; }
        h2 { break-after: avoid; }
        .table-scroll { overflow: visible; }
      }
    </style>
  </head>
  <body id="top">
    <a class="skip-link" href="#policy">본문으로 바로가기</a>
    <header class="site-header">
      <div class="site-header__inner">
        <a class="brand" href="#top" aria-label="AICO 개인정보처리방침 맨 위로">
          <img class="brand__icon" src="./assets/aico-app-icon.jpg" width="30" height="30" alt="">
          <span>AICO</span>
        </a>
        <span class="site-header__section">개인정보 보호</span>
      </div>
    </header>
    <main class="page">
      <header class="hero">
        <p class="eyebrow">Privacy</p>
        <div class="hero__title-row">
          <h1>AICO 개인정보처리방침</h1>
          <img class="hero__character" src="./assets/aico-character.png" width="440" height="440" alt="" fetchpriority="high">
        </div>
        <p class="hero__lead">AICO가 개인정보를 수집·이용·보관·공유하는 방법과 이용자가 자신의 정보를 관리하는 방법을 안내합니다.</p>
        <ul class="hero-meta" aria-label="문서 정보">
          <li>#{inline_html(updated_date)} 업데이트</li>
          <li>시행일 #{inline_html(effective_date)}</li>
          <li>버전 #{inline_html(policy_version)}</li>
        </ul>
      </header>

      <section class="principles" aria-label="AICO 개인정보 보호 원칙">
        <div class="principles__inner">
          <div class="principle">
            <span class="principle__number">01</span>
            <strong>기기 우선 저장</strong>
            <p>입력한 정보는 기본적으로 사용자의 iPhone에 저장됩니다.</p>
          </div>
          <div class="principle">
            <span class="principle__number">02</span>
            <strong>선택적 공동돌봄</strong>
            <p>사용자가 공유 기능을 선택한 경우에만 CloudKit을 통해 공유됩니다.</p>
          </div>
          <div class="principle">
            <span class="principle__number">03</span>
            <strong>광고·추적 없음</strong>
            <p>AICO는 광고 또는 사용자 행동 분석 SDK를 사용하지 않습니다.</p>
          </div>
        </div>
      </section>

      <div class="layout">
        <nav class="toc" aria-label="이 페이지의 목차">
          <strong>이 페이지에서</strong>
          <ol>
            #{nav_html}
          </ol>
        </nav>

        <article id="policy">
          <details class="mobile-toc">
            <summary>이 페이지에서</summary>
            <ol>
              #{nav_html}
            </ol>
          </details>
          <div class="policy-body">
            #{body.join("\n")}
          </div>
        </article>
      </div>
    </main>
    <footer>
      <div class="footer__inner">
        <p>© 2026 AICO · 개인정보 보호책임자 우상영 · <a href="mailto:sangyoung2730@naver.com">sangyoung2730@naver.com</a></p>
        <a class="back-to-top" href="#top">맨 위로</a>
      </div>
    </footer>
    <script>
      const links = Array.from(document.querySelectorAll('.toc a'));
      const sections = links
        .map((link) => document.querySelector(link.getAttribute('href')))
        .filter(Boolean);

      if ('IntersectionObserver' in window) {
        const observer = new IntersectionObserver((entries) => {
          const visible = entries
            .filter((entry) => entry.isIntersecting)
            .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top)[0];
          if (!visible) return;

          links.forEach((link) => {
            const isCurrent = link.getAttribute('href') === `#${visible.target.id}`;
            if (isCurrent) link.setAttribute('aria-current', 'true');
            else link.removeAttribute('aria-current');
          });
        }, { rootMargin: '-18% 0px -72% 0px' });

        sections.forEach((section) => observer.observe(section));
      }
    </script>
  </body>
  </html>
HTML

File.write(OUTPUT_PATH, document)
