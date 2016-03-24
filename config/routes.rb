Rails.application.routes.draw do

  ActiveAdmin.routes(self)

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks", registrations: 'registrations', sessions: 'sessions'}
  # root to: 'restaurants#index'

  devise_scope :user do
    root :to => 'devise/sessions#new'
  end

  resources :users, only: [:show] do
    collection do
      get :welcome_ceo
      post :update_password
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

    resources :users, only: :show do
      collection do
        get  :welcome_ceo
        get  :reset_badge_to_zero
        get  :update_version
        get  :score
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
    resources :friendships, only: [:index, :destroy]
    resources :followerships, only: [:index, :new]
    resources :wishes, only: [:index, :create]
    resources :registrations, only: [:edit, :update, :new, :create]
    resources :sessions, only: [:create]
    resources :user_wishlist_pictures, only: [:new, :create]
    resources :restaurants, only: [:show, :index] do
      collection do
        get :autocomplete
      end
    end

    namespace :v2 do
      resources :users, only: [:index, :show, :update] do
        collection do
          get  :welcome_ceo
          get  :reset_badge_to_zero
          get  :update_version
          get  :score
          get  :experts
          get  :pertinent_experts
          post :new_parse_installation
          post :contacts_access
          post :invite_contact
          post :update_password
          post :update_picture
        end
      end
      resources :recommendations, only: [:index, :create, :destroy, :update]
      resources :friendships, only: [:index, :destroy] do
        collection do
          post :ask
          post :accept
          post :refuse
          post :make_invisible
          post :make_visible
        end
      end
      resources :followerships, only: [:index, :create, :destroy]
      resources :wishes, only: [:index, :new, :create, :destroy]
      resources :registrations, only: [:new, :create]
      resources :sessions, only: [:create] do
        collection do
          post :update_infos
        end
      end
      resources :activities, only: [:index, :show]
      resources :user_wishlist_pictures, only: [:new, :create]
      resources :restaurants, only: [:show, :index, :update] do
        collection do
          get :autocomplete
          get :user_updated
        end
        member do
          post :add_pictures
        end
      end
    end

  end
end
