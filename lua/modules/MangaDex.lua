function getinfo()
  mangainfo.url=MaybeFillHost(module.rooturl,url)
  http.cookies.values['mangadex_h_toggle'] = '1'
  local id = url:match('title/(%d+)')
  if id == nil then id = url:match('manga/(%d+)'); end
  if http.get(MaybeFillHost(module.rooturl, '/api/manga/' .. id)) then
    local resp = HTMLEncode(StreamToString(http.document))
    local x = TXQuery.Create(resp)
    
    local info = x.xpath('json(*)')
    if mangainfo.title == '' then
      mangainfo.title = x.xpathstring('manga/title', info)
    end
    mangainfo.coverlink = MaybeFillHost(module.rooturl, x.xpathstring('manga/cover_url', info))
    mangainfo.authors = x.xpathstring('manga/author', info)
    mangainfo.artists = x.xpathstring('manga/artist', info)
    mangainfo.summary = x.xpathstring('manga/description', info)
    mangainfo.status = MangaInfoStatusIfPos(x.xpathstring('manga/status', info), '1', '2')
    
    local genres = ''
    local v = x.xpath('jn:members(manga/genres)', info)
    if v.count > 0 then genres = getgenre(v.get(1).toString); end
    for i = 2, v.count do
      local v1 = v.get(i)
      genres = genres .. ', ' .. getgenre(v1.toString)
    end
    mangainfo.genres = genres
    
    local chapters = x.xpath('let $c := json(*).chapter return for $k in jn:keys($c) ' ..
      'return jn:object(object(("chapter_id", $k)), $c($k))')
    for i = 1, chapters.count do
      local v1 = chapters.get(i)
      local lang = x.xpathstring('lang_code', v1)
      local ts = tonumber(x.xpathstring('timestamp', v1))
      if (module.getoption('luashowalllang') or lang == 'gb') and (ts <= os.time()) then
        mangainfo.chapterlinks.add('/chapter/' .. x.xpathstring('chapter_id', v1))
        local s = string.format('Vol. %s Ch. %s', x.xpathstring('volume', v1),
          x.xpathstring('chapter', v1))
        
        local title = x.xpathstring('title', v1)
        if title ~= '' then s = string.format('%s - %s', s, title); end
        if module.getoption('luashowalllang') then
          s = string.format('%s [%s]', s, getlang(lang))
        end
        
        if module.getoption('luashowscangroup') then
          local group = x.xpathstring('group_name', v1)
          local group2 = x.xpathstring('group_name_2', v1)
          local group3 = x.xpathstring('group_name_3', v1)
          if group2:len() > 0 and group2 ~= 'null' then
            group = group .. ' | ' .. group2
          end
          if group3:len() > 0 and group3 ~= 'null' then
            group = group .. ' | ' .. group3
          end
          s = string.format('%s [%s]', s, group)
        end
        
        mangainfo.chapternames.add(s)
      end
    end
    
    InvertStrings(mangainfo.chapterlinks,mangainfo.chapternames)
    return no_error
  else
    return net_problem
  end
end

function getgenre(genre)
  local genres = {
    ["1"] = "4-koma",
    ["2"] = "Action",
    ["3"] = "Adventure",
    ["4"] = "Award Winning",
    ["5"] = "Comedy",
    ["6"] = "Cooking",
    ["7"] = "Doujinshi",
    ["8"] = "Drama",
    ["9"] = "Ecchi",
    ["10"] = "Fantasy",
    ["11"] = "Gender Bender",
    ["12"] = "Harem",
    ["13"] = "Historical",
    ["14"] = "Horror",
    ["15"] = "Josei",
    ["16"] = "Martial Arts",
    ["17"] = "Mecha",
    ["18"] = "Medical",
    ["19"] = "Music",
    ["20"] = "Mystery",
    ["21"] = "Oneshot",
    ["22"] = "Psychological",
    ["23"] = "Romance",
    ["24"] = "School Life",
    ["25"] = "Sci-Fi",
    ["26"] = "Seinen",
    ["27"] = "Shoujo",
    ["28"] = "Shoujo Ai",
    ["29"] = "Shounen",
    ["30"] = "Shounen Ai",
    ["31"] = "Slice of Life",
    ["32"] = "Smut",
    ["33"] = "Sports",
    ["34"] = "Supernatural",
    ["35"] = "Tragedy",
    ["36"] = "Webtoon",
    ["37"] = "Yaoi",
    ["38"] = "Yuri",
    ["39"] = "[no chapters]",
    ["40"] = "Game",
    ["41"] = "Isekai"
  }
  if genres[genre] ~= nil then
    return genres[genre]
  else
    return genre
  end
end

function getlang(lang)
  local langs = {
    ["sa"] = "Arabic",
    ["bd"] = "Bengali",
    ["bg"] = "Bulgarian",
    ["mm"] = "Burmese",
    ["ct"] = "Catalan",
    ["cn"] = "Chinese (Simp)",
    ["hk"] = "Chinese (Trad)",
    ["cz"] = "Czech",
    ["dk"] = "Danish",
    ["nl"] = "Dutch",
    ["gb"] = "English",
    ["ph"] = "Filipino",
    ["fi"] = "Finnish",
    ["fr"] = "French",
    ["de"] = "German",
    ["gr"] = "Greek",
    ["hu"] = "Hungarian",
    ["id"] = "Indonesian",
    ["it"] = "Italian",
    ["jp"] = "Japanese",
    ["kr"] = "Korean",
    ["my"] = "Malay",
    ["mn"] = "Mongolian",
    ["ir"] = "Persian",
    ["pl"] = "Polish",
    ["br"] = "Portuguese (Br)",
    ["pt"] = "Portuguese (Pt)",
    ["ro"] = "Romanian",
    ["ru"] = "Russian",
    ["rs"] = "Serbo-Croatian",
    ["es"] = "Spanish (Es)",
    ["mx"] = "Spanish (LATAM)",
    ["se"] = "Swedish",
    ["th"] = "Thai",
    ["tr"] = "Turkish",
    ["ua"] = "Ukrainian",
    ["vn"] = "Vietnamese"
  }
  if langs[lang] ~= nil then
    return langs[lang]
  else
    return langs
  end
end

function getpagenumber()
  http.cookies.values['mangadex_h_toggle'] = '1'
  local chapterid = url:match('chapter/(%d+)')
  if http.get(MaybeFillHost(module.rooturl,'/api/chapter/'..chapterid)) then
    local x=TXQuery.Create(http.Document)
    local hash = x.xpathstring('json(*).hash')
    local srv = x.xpathstring('json(*).server')
    local v = x.xpath('json(*).page_array()')
    for i = 1, v.count do
      local v1 = v.get(i)
      local s = MaybeFillHost(module.rooturl, srv .. '/' .. hash .. '/' .. v1.toString)
      task.pagelinks.add(s)
    end
    return true
  else
    return false
  end
  return true
end

local dirurl='/titles/2'

function getdirectorypagenumber()
  http.cookies.values['mangadex_h_toggle'] = '1'
  http.cookies.values['mangadex_title_mode'] = '2'
  if http.GET(module.RootURL .. dirurl) then
    local x = TXQuery.Create(http.Document)
    page = tonumber(x.xpathstring('(//ul[contains(@class,"pagination")]/li/a)[last()]/@href'):match('/2/(%d+)'))
    if page == nil then page = 1 end
    return no_error
  else
    return net_problem
  end
end

function getnameandlink()
  http.cookies.values['mangadex_h_toggle'] = '1'
  http.cookies.values['mangadex_title_mode'] = '2'
  if http.GET(module.rooturl .. dirurl .. '/' .. IncStr(url) .. '/') then
    local x = TXQuery.Create(http.document)
    x.xpathhrefall('//a[contains(@class, "manga_title")]',links,names)
    return no_error
  else
    return net_problem
  end
end

function Init()
  m=NewModule()
  m.category='English'
  m.website='MangaDex'
  m.rooturl='https://mangadex.org'
  m.lastupdated='February 28, 2018'
  m.ongetinfo='getinfo'
  m.ongetpagenumber='getpagenumber'
  m.ongetnameandlink='getnameandlink'
  m.ongetdirectorypagenumber = 'getdirectorypagenumber'
  
  m.maxtasklimit=1
  m.maxconnectionlimit=2

  m.addoptioncheckbox('luashowalllang', 'Show all language', false)
  m.addoptioncheckbox('luashowscangroup', 'Show scanlation group', false)
end
