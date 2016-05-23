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
json.map_onboarding            @user.map_onboarding
json.restaurant_onboarding     @user.restaurant_onboarding
json.followings_onboarding     @user.followings_onboarding
json.profile_onboarding        @user.profile_onboarding
json.recommendation_onboarding @user.recommendation_onboarding
if @user.id == @myself.id
  json.notifications_read_date @user.notifications_read_date
  json.thanks                  @thanks
  json.provider                @user.provider
end



