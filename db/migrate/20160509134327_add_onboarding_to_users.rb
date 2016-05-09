class AddOnboardingToUsers < ActiveRecord::Migration
  def change
    add_column :users, :map_onboarding, :boolean, default: false
    add_column :users, :restaurant_onboarding, :boolean, default: false
    add_column :users, :followings_onboarding, :boolean, default: false
    add_column :users, :profile_onboarding, :boolean, default: false
    add_column :users, :recommendation_onboarding, :boolean, default: false
  end
end
