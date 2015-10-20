json.experts             @experts do |expert|
  json.name              expert.name
  json.picture           expert.picture
  json.id                expert.id
  json.number_of_recos   Recommendation.where(expert_id: expert.id).count
  json.status            @user.followings.include?(expert) ? 'Ne plus suivre' : 'Suivre'
end

