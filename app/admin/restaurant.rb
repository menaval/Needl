ActiveAdmin.register Restaurant do

  permit_params :name, :address, :food_id, :longitude, :latitude, :phone_number, :picture_url, :price_range, :city, :postal_code, :full_address, :starter1, :starter2, :price_starter1, :price_starter2, :main_course1, :main_course2, :main_course3, :price_main_course1, :price_main_course2, :price_main_course3, :dessert1, :dessert2, :price_dessert1, :price_dessert2, :description_starter1, :description_starter2, :description_main_course1, :description_main_course2, :description_main_course3, :description_dessert1, :description_dessert2, :food_name, :subway_name, :subways_near

  form do |f|
    f.inputs "Restaurant" do
      f.input :food, collection: Food.all.order(:name)
      f.input :name
      f.input :address
      f.input :city
      f.input :postal_code
      f.input :full_address
      f.input :price_range
      f.input :phone_number
      f.input :starter1
      f.input :description_starter1
      f.input :price_starter1
      f.input :starter2
      f.input :description_starter2
      f.input :price_starter2
      f.input :main_course1
      f.input :description_main_course1
      f.input :price_main_course1
      f.input :main_course2
      f.input :description_main_course2
      f.input :price_main_course2
      f.input :main_course3
      f.input :description_main_course3
      f.input :price_main_course3
      f.input :dessert1
      f.input :description_dessert1
      f.input :price_dessert1
      f.input :dessert2
      f.input :description_dessert2
      f.input :price_dessert2
      f.input :latitude
      f.input :longitude
      f.input :picture_url
      f.input :food_name
      f.input :subway_name
      f.input :subways_near
      f.file_field :picture
    end
    f.actions
  end

  batch_action :new_restaurant do |ids|
    Restaurant.find(ids).each do |restaurant|
      # ajouter le food name
      restaurant.food_name = Food.find(restaurant.food_id).name
      # ajout des metros


      client = GooglePlaces::Client.new(ENV['GOOGLE_API_KEY'])

      # stations erronnées reconnaissables à leur nom


      false_subway_stations_by_name = [
        "Elysees Metro Hub", "Métro invalides",
        "Metro Saint-Paul",
        "Metro Station Anvers",
        "Métro Saint Germain des Près",
        "Paris train station",
        "Station de Métro Les Halles",
        "Paris Est"]

        false_subway_stations_by_coordinates = [
          [48.870871, 2.332217],
          [48.876305, 2.333199],
          [48.831483, 2.355692],
          [48.869644, 2.336445],
          [48.853387, 2.343706],
          [48.867531, 2.313542],
          [48.882598, 2.309639],
          [48.865299, 2.374381],
          [48.861272, 2.374214]]


      search_less_than_500_meters = client.spots(restaurant.latitude, restaurant.longitude, :radius => 500, :types => 'subway_station')

      # on enleve toutes les stations erronees

      search_less_than_500_meters.delete_if { |result| false_subway_stations_by_name.include?(result.name)}
      search_less_than_500_meters.delete_if do|result|
        coordinates_result = [result.lat, result.lng]
        false_subway_stations_by_coordinates.include?(coordinates_result)
      end

      # recherche du plus près au cas où il n'y en ait pas dans les 500m

      search_by_closest = client.spots(restaurant.latitude, restaurant.longitude, :rankby => 'distance', :types => 'subway_station')[0..5]

      # on enlève toutes les stations erronées
      search_by_closest.delete_if { |result| !false_subway_stations_by_name.include?(result.name)}
      search_by_closest.delete_if do|result|
        coordinates_result = [result.lat, result.lng]
        false_subway_stations_by_coordinates.include?(coordinates_result)
      end
      search_by_closest = search_by_closest.first
      # on récupère le tout

      search = search_less_than_500_meters.length > 0 ? search_less_than_500_meters : [search_by_closest]

      # on associe chaque station de metro au restaurant

      search.each do |result|
        if Subway.find_by(latitude: result.lat) == nil

          #  on cree le metro sil nexiste pas

          subway = Subway.create(
            name:      result.name,
            latitude:  result.lat,
            longitude: result.lng
            )
          result = Geocoder.search("#{result.lat}, #{result.lng}").first.data["address_components"]
          result.each do |component|
            if component["types"].include?("locality")
              city = component["long_name"]
              subway.city = city
              subway.save
            end
          end

        else
          subway = Subway.find_by(latitude: result.lat)
        end
        restaurant_subway = RestaurantSubway.create(
          restaurant_id: restaurant.id,
          subway_id:     subway.id
          )
      end
      # enregistrer les subways dans la base de données restos pour rendre plus rapidement l'api
      restaurant.subway_id = restaurant.closest_subway_id
      restaurant.subway_name = Subway.find(restaurant.subway_id).name
      array = []
      restaurant.subways.each do |subway|
        array << {subway.id => subway.name}
      end
      restaurant.subways_near = array

      restaurant.save

    end
    redirect_to admin_restaurants_path, alert: "Restaurant complété"
  end

end
