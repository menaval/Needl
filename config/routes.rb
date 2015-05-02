Rails.application.routes.draw do

  ActiveAdmin.routes(self)

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks", registrations: 'registrations' }
  root to: 'restaurants#index'

  resources :users, only: [:show, :edit, :update]
  resources :friendships, only: [:index, :new, :create] do
    collection do
      post :answer_request
      post :not_interested
      post :unfriend
      get :my_friends
    end
  end

  resources :restaurants, only: [:show, :index]

  resources :recommendations, only: [:index, :new, :create]
end
