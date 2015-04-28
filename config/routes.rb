Rails.application.routes.draw do

  ActiveAdmin.routes(self)
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  resources :users, only: [:show, :edit, :update]
  resources :friendships, only: [:index, :new, :create, :destroy]

  resources :restaurants, only: [:show, :index] do
    resources :recommendations, only: [:new, :create]
  end

  resources :recommendations, only: :index
end
