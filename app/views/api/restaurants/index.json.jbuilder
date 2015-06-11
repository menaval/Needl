json.array! @restaurants do |restaurant|
  json.id restaurant.id
  json.name restaurant.name
  json.address restaurant.address
  json.origin restaurant.origin
  json.name_and_address restaurant.name_and_address
end
