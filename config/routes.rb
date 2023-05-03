Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  # ============ PAGES ============#
  root 'pages#home'
  get 'search', to: 'pages#search'

  # ============ AUTH =============#
  post '/auth/login', to: 'authentication#login'
  post '/auth/signup', to: 'authentication#signup'
  post '/auth/update', to: 'authentication#update'
  get '/auth/me', to: 'authentication#get_current_user'
  put 'users/:id', to: 'authentication#update'

  # ============ USERS ============#
  get 'signup', to: 'users#new'
  get 'users/top', to: "users#top_users"
  resources :users, except: [:new, :update]
  post 'follow/:user_id', to: 'users#follow'
  post 'unfollow/:user_id', to: 'users#unfollow'

  # ============ SESSION ============#
  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'


  # ============ ARTICLES ============#
  get 'articles/featured', to: 'articles#featured_articles'
  resources :articles
  post 'article/:id/upvote', as: 'upvote', to: 'articles#upvote'

  # ============ CATEGORIES ============#
  get 'categories/top', to: "categories#top_categories"
  resources :categories

  # ============ MESSAGES ============#
  resources :messages, only: %i[new create index]
  resources :messages, path: 'community', only: %i[new create index]
end
