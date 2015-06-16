json.requests     @requests do |request|
  json.name       request.name.split(" ")[0]
  json.picture    request.picture
end
json.friends      @friends do |friend|
  json.name       friend.name.split(" ")[0]
  json.picture    friend.picture
end

