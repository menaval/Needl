json.experts           @all_experts do |expert|
  json.id                      expert.id
  json.name                    expert.name.split(" ")[0]
  json.fullname                expert.name
  json.picture                 expert.picture
  json.score                   expert.score
  json.invisible               false
  json.correspondence_score    0
  json.recommendations         @experts_recommendations[expert.id] ? @experts_recommendations[expert.id] : []
  json.wishes                  @experts_wishes[expert.id] ? @experts_wishes[expert.id] : []
  json.followings              @experts_followings[expert.id] ? @experts_followings : []
  json.public                  expert.public
  json.public_score            expert.public_score
  json.number_of_followers     @experts_followers[expert.id] ? @experts_followers[expert.id].length : 0
  json.description             expert.description
  json.tags                    expert.tags
  json.public_recommendations  @experts_public_recommendations[expert.id] ? @experts_public_recommendations[expert.id] : []
  json.url                     expert.url
end