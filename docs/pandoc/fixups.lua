-- UsersManual_Software_JP.md → PDF 変換用フィルタ

-- 1) 表ヘッダ内の生 HTML <br> を LaTeX の改行に変換する
function RawInline(el)
  if el.format:match('^html') and el.text:lower():match('^%s*<%s*br%s*/?%s*>%s*$') then
    return pandoc.LineBreak()
  end
end

-- 2) <sub>…</sub> を下付き文字に変換する。
--    pandoc は markdown 中の <sub> を生 HTML のまま残し、LaTeX 出力では捨ててしまうため、
--    開きタグと閉じタグの間を Subscript にまとめ直す。
local function is_tag(el, name)
  return el.t == 'RawInline' and el.format:match('^html')
     and el.text:lower():match('^%s*<%s*' .. name .. '%s*>%s*$') ~= nil
end

function Inlines(inlines)
  local out, buf = pandoc.Inlines{}, nil
  for _, el in ipairs(inlines) do
    if buf == nil and is_tag(el, 'sub') then
      buf = pandoc.Inlines{}
    elseif buf ~= nil and is_tag(el, '/sub') then
      out:insert(pandoc.Subscript(buf))
      buf = nil
    elseif buf ~= nil then
      buf:insert(el)
    else
      out:insert(el)
    end
  end
  if buf ~= nil then -- 閉じタグが無ければ元のまま出す
    out:insert(pandoc.RawInline('html', '<sub>'))
    out:extend(buf)
  end
  return out
end

-- 3) 手書き目次のアンカー切れを修正する。
--    目次のアンカーは GitHub 流（[…]{.ul} を文字通りの文字列として読む）で付けられて
--    いるため、span として解釈する pandoc の見出し ID と一致しない。記号を落として
--    正規化し、必要なら {.ul} 由来の末尾 "ul" を取り除いて突き合わせる。
local function norm(s)
  return (s:lower():gsub('[%p%s]', ''))
end

function Pandoc(doc)
  local ids = {}
  doc:walk{
    Header = function(h)
      if h.identifier ~= '' then ids[norm(h.identifier)] = h.identifier end
    end
  }
  return doc:walk{
    Link = function(l)
      if l.target:sub(1, 1) ~= '#' then return nil end
      local key = norm(l.target:sub(2))
      local id = ids[key] or ids[(key:gsub('ul$', ''))]
      if id then
        l.target = '#' .. id
        return l
      end
    end
  }
end
