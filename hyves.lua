dofile("urlcode.lua")

local url_count = 0
local new_url_count = 0
local hyves_username = os.getenv("hyves_username")

read_file = function(file)
  if file then
    local f = io.open(file)
    local data = f:read("*all")
    f:close()
    return data or ""
  else
    return ""
  end
end

read_file_short = function(file)
  if file then
    local f = io.open(file)
    local data = f:read(4096)
    f:close()
    return data or ""
  else
    return ""
  end
end


-- range(a) returns an iterator from 1 to a (step = 1)
-- range(a, b) returns an iterator from a to b (step = 1)
-- range(a, b, step) returns an iterator from a to b, counting by step.
-- http://lua-users.org/wiki/RangeIterator
function range(a, b, step)
  if not b then
    b = a
    a = 1
  end
  step = step or 1
  local f =
  step > 0 and
  function(_, lastvalue)
    local nextvalue = lastvalue + step
    if nextvalue <= b then return nextvalue end
  end or
  step < 0 and
  function(_, lastvalue)
    local nextvalue = lastvalue + step
    if nextvalue >= b then return nextvalue end
  end or
  function(_, lastvalue) return lastvalue end
  return f, nil, a - step
end

add_urls_from_pager = function(html, urls, hostname, current_url)
  local name = string.match(html, "name:%s*'([^']+)'")
  local num_pages = tonumber(string.match(html, "nrPages:%s*([0-9]+)"))
  local extra = string.match(html, "extra:%s*'([^']+)'")

  if not name or not num_pages or not extra then
    io.stdout:write("\nPager not found: url="..current_url.." name="..tostring(name).." num_pages="..tostring(num_pages).." extra="..tostring(extra).."\n")
    io.stdout:flush()
    return
  end

  for page_number in range(1, num_pages) do

    local fields = {}

    fields["pageNr"] = page_number
    fields["config"] = "hyvespager-config.php"
    fields["showReadMoreLinks"] = "false"
    fields["extra"] = extra

    table.insert(urls, {
      url="http://"..hostname.."/index.php?xmlHttp=1&module=pager&action=showPage&name="..name,
      post_data=cgilua.urlcode.encodetable(fields)
    })

    new_url_count = new_url_count + 1
  end
end

wget.callbacks.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
  if verdict then
    local sleep_time = 0.75 * (math.random(50, 150) / 100.0)

    if string.match(urlpos["url"]["url"], "hyves%-static.net") then
      -- We should be able to go fast on images since that's what a web browser does
      sleep_time = 0
    end

    if sleep_time > 0.001 then
      --    io.stdout:write("\nSleeping=".. sleep_time .." url="..urlpos["url"]["url"].." verdict="..tostring(verdict).."\n")
      --    io.stdout:flush()
      os.execute("sleep " .. sleep_time)
    end
  end

  return verdict
end

wget.callbacks.httploop_result = function(url, err, http_stat)
  local html = read_file_short(http_stat["local_file"])
  local sleep_time = 10

  if string.match(html, "Try again in a moment") then
    io.stdout:write("\nHyves angered (code "..http_stat.statcode.."). Sleeping for ".. sleep_time .." seconds.\n")
    io.stdout:flush()
    os.execute("sleep " .. sleep_time)
    return wget.actions.CONTINUE
  end

  return wget.actions.NOTHING
end

wget.callbacks.get_urls = function(file, url, is_css, iri)
  -- progress message
  url_count = url_count + 1
  if url_count % 5 == 0 then
    io.stdout:write("\r - Downloaded "..url_count.." URLs. Discovered "..new_url_count.." URLs.")
    io.stdout:flush()
  end

  local urls = {}
  local html = nil
  local hostname = string.match(url, "http://([^/]+)")

  -- paginate the friends (quickfinder_member_friends)
  if string.match(url, "hyves.nl/vrienden/") or string.match(url, "hyves.nl/friends/") or
  -- paginate the photos (albumlistwithpreview)
  string.match(url, "hyves.nl/fotos/") or string.match(url, "hyves.nl/photos/") or
  -- paginate the group members (quickfinder_hub_members)
  string.match(url, "hyves.nl/leden/") or string.match(url, "hyves.nl/members/") or
  -- paginate the blog (blog_mainbody / hub_content)
  string.match(url, "hyves.nl/blog/") then
    if not html then
      html = read_file(file)
    end
    add_urls_from_pager(html, urls, hostname, url)
  end

  -- TODO: check to see if we need to paginate other stuff

  -- scrape out the urls from the html fragment from the pagination request
  -- or urls from the html fragment of the photo comments
  if string.match(url, "/index.php%?xmlHttp=1&module=pager") or
  string.match(url, "module=PhotoBrowser&action=postGetSocialPage") then
    if not html then
      html = read_file(file)
    end
    for requisite_url in string.gmatch(html, "=['\"](http[%w%.:/-]+hyves%-static%.net[^'\"]+)['\"]") do
      table.insert(urls, { url=requisite_url })
      --      io.stdout:write("\nPager new url="..requisite_url.."\n")
      --      io.stdout:flush()
      new_url_count = new_url_count + 1
    end
  end

  -- Grab large size photos (change 16 into a 6 ???) from photo album only.
  -- TODO: check referer to see if we are coming from an album and not from a
  -- photo comment page. Getting the comment page on an image from a comment
  -- page would be recursion across users.
  if string.match(url, "http://[0-9].media.hyves%-static.net/[0-9]+/16/[%w_-]+/[0-9]+/[%w.]+") then
    local hostnum, img_id, secret, something, filename = string.match(url, "http://([0-9]).media.hyves%-static.net/([0-9]+)/16/([%w_-]+)/([0-9]+)/([%w.]+)")
    local photo_url = "http://"..hostnum..".media.hyves-static.net/"..img_id.."/6/"..secret.."/"..something.."/"..filename
    table.insert(urls, { url=photo_url })
    new_url_count = new_url_count + 1

    -- grab the html fragment containing the photo comments and the "respects"
    local photo_meta_url = "http://"..hyves_username..".hyves.nl/?module=PhotoBrowser&action=postGetSocialPage"
    -- the order of these fields actually matters..
    -- the secret should be same as GP cookie value
    local post_data_fields = "itemType=4&postman_secret=deadbeef&itemApiId=&itemId="..img_id.."&itemSecret="..secret

    table.insert(urls, {
      url=photo_meta_url,
      post_data=post_data_fields
    })

    new_url_count = new_url_count + 1
  end

  return urls
end

