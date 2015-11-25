# "This task is called by the Heroku scheduler add-on"
task :update_feed => :environment do

  if Time.now.wday != 5
    puts "Nothing Today."
  else
    puts "Updating mailchimp infos ..."
    User.all.each do |user|
      restaurants_ids = user.my_friends_restaurants_ids
      types_ids = [5, 11, 2, 9, 8, 12, 17, 15, 10]
      Type.all.each do |type|
        puts "waiting .."
      end
    end
    puts "done."
  end
end

# ok: Verifier si on est vendredi matin (très tot)
# ok: isoler un user
# ok: récupérer la liste des restaurants
# regarder pour chaque type/occasion, dans un ordre précis (pour l'instant c'est: Japonais - Burger - Thaï - Italien - Français - Street Food - Oriental - Pizza), et en enlevant ceux déjà tombés, le nombre de restaurants qui tombent dedans de moins d'un mois
# Si le nombre dépasse 2, ça casse la boucle et on récupère le nom du thème dans une variable
# On récupère toutes les recommandations laissées par les potes (sauf Needl)
# Si plus de 3 (exclu) avec un commentaire différent de "Je recommande!", ne prendre que ceux là. Sinon les prendre tous
# Les trier du plus récent au plus vieux
# Si seulement 2, rajouter une de Needl dans cette catégorie
# Faire une boucle sur les 3 et récupérer dans des variables le nom, le type ou la catégorie, le metro, l'id, l'image, le nom du pote et sa review.
# Si jamais 2 par catégorie, on refait une boucle avec seulement les recos Needl
# Updater les infos de mailchimp (upsert)
# Enregistrer le thème dans une base : ça peut etre un tableau dans le modèle User et le retirer au tableau retenu des types.
# Si l'utilisateur les a tous fait, repartir à 0 (vider le tableau si la length == 9)

