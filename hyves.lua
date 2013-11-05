local url_count = 0
local new_url_count = 0

read_file = function(file)
    if file then
        local f = io.open(file)
        local data = f:read("*all")
        f:close()
        return data
    else
        return ""
    end
end

wget.callbacks.get_urls = function(file, url, is_css, iri)
    -- progress message
    url_count = url_count + 1
    if url_count % 5 == 0 then
        io.stdout:write("\r - Downloaded "..url_count.." URLs. Discovered "..new_url_count.." URLs")
        io.stdout:flush()
    end
    
    -- TODO: paging stuff
end
