json.experts           @experts do |expert|
  json.name                 expert.name.split(" ")[0]
  json.fullname             expert.name
  json.picture              expert.picture
  json.id                   expert.id
  json.public_score         expert.public_score
  json.number_of_followers  @experts_followers[expert.id] ? @experts_followers[expert.id].length : 0
  json.followers            @experts_followers[expert.id] ? @experts_followers[expert.id] : []
  json.number_of_recos      @experts_recommendations[expert.id] ? @experts_recommendations[expert.id].length : 0
  json.recommendations      @experts_recommendations[expert.id] ? @experts_recommendations[expert.id] : []
end