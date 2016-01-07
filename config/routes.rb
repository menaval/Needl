Rails.application.routes.draw do

  ActiveAdmin.routes(self)

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks", registrations: 'registrations'}
  # root to: 'restaurants#index'

  devise_scope :user do
    root :to => 'devise/sessions#new'
  end

  resources :users, only: [:show] do
    collection do
      get :welcome_ceo
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

  resources :subscribers, only: [:create]

  resources :recommendations, only: [:index, :new, :create, :destroy] do
    collection do
      post :read_all_notifications
    end
  end

  resources :wishes, only: [:new, :create, :destroy]

  namespace :api, defaults: { format: :json } do
    resources :restaurants, only: [:show, :index] do
      collection do
        get :autocomplete
      end
    end
    resources :users, only: :show do
      collection do
        get  :welcome_ceo
        get  :reset_badge_to_zero
        get :update_version
        post :new_parse_installation
        post :contacts_access
        post :invite_contact
      end
    end
    resources :recommendations, only: [:index, :new] do
      collection do
        get :modify
      end
    end

    resources :friendships, only: [:index, :new]
    resources :wishes, only: [:index, :create]
    resources :registrations, only: [:edit, :update]
    resources :user_wishlist_pictures, only: [:new, :create]
  end
end
