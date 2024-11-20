Rails.application.routes.draw do
  resources :websites, only: [:new, :create, :show] do
    member do
      get "pages/:page_name", to: "websites#page", as: "page"
      get "pages/:page_name/edit", to: "websites#edit_page", as: "edit_page"
      patch "pages/:page_name", to: "websites#update_page", as: "update_page"
      patch "pages/:page_name/preview", to: "websites#preview_page", as: "preview_page"
    end
  end
  root "websites#new"
end
