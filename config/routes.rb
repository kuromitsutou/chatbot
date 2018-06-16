Rails.application.routes.draw do
  resources :chats, only: [:index]
end
