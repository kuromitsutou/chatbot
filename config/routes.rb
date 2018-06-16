Rails.application.routes.draw do
  post '/chats', to: 'chats#index'
end
