Rails.application.routes.draw do

  ActiveAdmin.routes(self)
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
  root to: 'restaurants#index'


  resources :users, only: [:show, :edit, :update]
  resources :friendships, only: [:index, :new, :create, :destroy] do
    collection do
      post :answer_request
    end
  end

  resources :restaurants, only: [:show, :index]

  resources :recommendations, only: [:index, :new, :create]
end
