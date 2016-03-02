json.id                        @user.id
json.name                      @user.name.split(" ")[0]
json.fullname                  @user.name
json.picture                   @user.picture
json.score                     @user.score
json.invisible                 @invisible
json.correspondence_score      @correspondence_score
json.recommendations           @recos
json.wishes                    @wishes
json.followings                @user.followings.pluck(:id)
json.public                    @user.public
json.public_score              @user.public_score
json.number_of_followers       @user.followers.length
json.description               @user.description
json.tags                      @user.tags
json.public_recommendations    @user.my_public_recos.pluck(:id)
json.url                       @user.url



