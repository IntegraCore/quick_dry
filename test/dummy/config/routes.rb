Rails.application.routes.draw do

  # resources :posts
  mount QuickDry::Engine => "/"

  # resources :comments

end
