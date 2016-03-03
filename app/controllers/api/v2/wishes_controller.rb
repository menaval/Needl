class Api::V2::WishesController < ApplicationController
  acts_as_token_authentication_handler_for User
  skip_before_action :verify_authenticity_token
  skip_before_filter :authenticate_user!


  def index
    if params["origin"] == mail
      create
    end
  end

  def create

    @user = User.find_by(authentication_token: params["user_token"])
    # si l'utilisateur a déjà mis sur sa liste de souhaits cet endroit alors on le lui dit. Et on vérifie qu'on ne choppe pas un id de foursquare non transformable en integer.
    if params["restaurant_id"].length <= 9 && Wish.where(restaurant_id:params["restaurant_id"].to_i, user_id: @user.id).any?

      if params["origin"] == "mail"
        sign_out
        render(:json => {notice: "Ce restaurant était déjà sur ta wishlist ! Tu peux le retrouver en te connectant sur l'app !"}, :status => 409, :layout => false)
      else

        render(:json => {notice: "Restaurant déjà sur ta wishlist"}, :status => 409, :layout => false)

      end

    # On vérifie qu'il n'a pas déjà recommandé l'endroit, sinon pas de raison de le mettre dans les restos à tester. La reaction dépend du fait qu"il vienne de l'app ou d'un mail
    elsif params["restaurant_id"].length <= 9 && Recommendation.where(restaurant_id:params["restaurant_id"].to_i, user_id: @user.id).length > 0

        if params["origin"] == "mail"
          sign_out
          render(:json => {notice: "Cette adresse fait déjà partie des restaurants que tu recommandes ! Tu peux le retrouver en te connectant sur l'app !"}, :status => 409, :layout => false)
        else

          render(:json => {notice: "Cette adresse fait déjà partie des restaurants que tu recommandes"}, :status => 409, :layout => false)
        end

    # Si c'est une nouvelle whish on check que la personne a bien choisi un resto parmis la liste et on identifie ou crée le restaurant via la fonction
    else
      identify_or_create_restaurant

      # On crée la recommandation à partir des infos récupérées et on track
      @wish = Wish.new(user_id: @user.id, restaurant_id: @restaurant.id)
      @wish.restaurant = @restaurant
      @wish.save
      @tracker.track(@user.id, 'New Wish', { "restaurant" => @restaurant.name, "user" => @user.name })

      #  Verifier si la wishlist vient de l'app ou d'un mail
      if params["origin"] == "mail"
        @tracker.track(@user.id, 'New Wish from Mail', { "restaurant" => @restaurant.name, "user" => @user.name })
        sign_out
        render(:json => {notice: "Le restaurant a bien été ajouté à ta wishlist ! Tu peux le retrouver en te connectant sur l'app !"}, :status => 409, :layout => false)

      else

        # AAAAAAAAAAAAAAAAAATTTTTTRRRRRRRRROOOOOOOOOOUUUUUUUUVVVVVVVVVEEEEEEEEEEERRRRRRR

        redirect_to api_v2_restaurant_path(@restaurant.id, :user_email => params["user_email"], :user_token => params["user_token"], :notice => "Restaurant ajouté à ta wishlist")

        # respond_to do |format|
        #   format.json  { render :json => {:restaurant => "api/v2/restaurants/show.json", params(id: @restaurant.id)
        #                                   :activity => "api/v2/activities/show.json", params(id: @wish.id, type: "wish") }}
        # end
      end
    end
  end


  def destroy
    @user = User.find_by(authentication_token: params["user_token"])
    wish = Wish.where(restaurant_id: params["id"].to_i, user_id: @user.id).first
    if PublicActivity::Activity.where(trackable_type: "Wish", trackable_id: wish.id).length > 0
      activity = PublicActivity::Activity.where(trackable_type: "Wish", trackable_id: wish.id).first
      activity.destroy
    end
    wish.destroy
    redirect_to api_v2_restaurant_path(id: params["id"].to_i, :user_email => params["user_email"], :user_token => params["user_token"], :notice => "Le restaurant a bien été retiré de la liste de vos envies", :status => 303)
  end

  private

  # def wish_params
  #   params.require(:wish).permit(:user_id, :restaurant_id)
  # end

  # je ne passe pas par les strong params, voir si c'est un problème


end