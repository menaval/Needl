Rails.application.routes.draw do

  ActiveAdmin.routes(self)

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks", registrations: 'registrations'}
  root to: 'restaurants#index'

  resources :users, only: [:show, :edit, :update] do
    collection do
      get :access
      get :welcome_ceo
      post :verification_code
    end
  end
  resources :friendships, only: [:index, :new, :create, :destroy] do
    collection do
      post :answer_request
      post :invisible
      post :visible
    end
  end

  resources :restaurants, only: [:show, :index] do
    member do
      get :map_box
    end
  end
  resources :not_interested_relations, only: [:create]

  resources :recommendations, only: [:index, :new, :create, :destroy] do
    collection do
      post :read_all_notifications
    end
  end

  resources :wishes, only: [:index, :new, :create, :destroy]

  namespace :api, defaults: { format: :json } do
    resources :restaurants, only: [:show, :index] do
      collection do
        get :autocomplete
      end
    end
    resources :users, only: :show
    resources :recommendations, only: [:index, :new]
    resources :friendships, only: [:index, :new]
    resources :wishes, only: [:index, :create]
    resources :registrations, only: [:edit, :update]
  end
end
