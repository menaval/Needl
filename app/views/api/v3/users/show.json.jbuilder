json.friendship_id             @friendship_id
json.id                        @user.id
json.name                      @user.name.split(" ")[0]
json.fullname                  @user.name
json.picture                   @user.picture
json.facebook_linked           @user.token ? true : false
json.score                     @user.score
json.invisible                 @invisible
json.app_version               @user.app_version
json.platform                  @user.platform
json.correspondence_score      @correspondence_score
json.recommendations           @recos
json.wishes                    @wishes
json.followings                @user.followings.pluck(:id)
json.friends                   @friends
json.public                    @user.public
json.public_score              @user.public_score
json.number_of_followers       @user.followers.length
json.description               @user.description
json.tags                      @user.tags
json.public_recommendations    @user.my_public_recos.pluck(:id)
json.url                       @user.url
json.map_overlay               @user.map_overlay
json.restaurant_overlay        @user.restaurant_overlay
json.followings_overlay        @user.followings_overlay
json.profile_overlay           @user.profile_overlay
json.recommendation_overlay    @user.recommendation_overlay
if @user.id == @myself.id
  json.thanks                  @thanks
  json.provider                @user.provider
end



