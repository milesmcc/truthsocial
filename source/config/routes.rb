# frozen_string_literal: true

require 'sidekiq_unique_jobs/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  root 'home#index'
  resources :apidocs, only: [:index]

  mount LetterOpenerWeb::Engine, at: 'letter_opener' if Rails.env.development?

  get 'health', to: 'health#show'

  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web, at: 'sidekiq', as: :sidekiq
  end

  namespace :oauth do
    scope :mfa do
      post :challenge, controller: 'mfa'
    end
  end

  use_doorkeeper do
    controllers authorizations: 'oauth/authorizations',
                authorized_applications: 'oauth/authorized_applications',
                tokens: 'oauth/tokens'
  end

  get '.well-known/host-meta', to: 'well_known/host_meta#show', as: :host_meta, defaults: { format: 'xml' }
  get '.well-known/webfinger', to: 'well_known/webfinger#show', as: :webfinger
  get '.well-known/change-password', to: redirect('/auth/edit')
  post '.well-known/skadnetwork/report-attribution/', to: 'well_known/skadnetwork#create'

  get 'manifest', to: 'manifests#show', defaults: { format: 'json' }
  get 'intent', to: 'intents#show'
  get 'custom.css', to: 'custom_css#show', as: :custom_css
  get '/unsubscribe', to: 'unsubscribe#unsubscribe'

  get '/link/:id', to: 'link#show', as: :link
  devise_scope :user do
    get '/invite/:invite_code', to: 'auth/registrations#new', as: :public_invite

    namespace :auth do
      resource :setup, only: [:show, :update], controller: :setup
      resource :challenge, only: [:create], controller: :challenges
      get 'sessions/security_key_options', to: 'sessions#webauthn_options'
    end
  end

  devise_for :users, path: 'auth', controllers: {
    omniauth_callbacks: 'auth/omniauth_callbacks',
    sessions: 'auth/sessions',
    registrations: 'auth/registrations',
    passwords: 'auth/passwords',
    confirmations: 'auth/confirmations',
  }

  get '/users/:username', to: redirect('/@%{username}'), constraints: lambda { |req| req.format.nil? || req.format.html? }

  resources :accounts, path: 'users', only: [:show], param: :username do
    get :remote_follow, to: 'remote_follow#new'
    post :remote_follow, to: 'remote_follow#create'

    resources :statuses, only: [:show] do
      member do
        get :activity
        get :embed
      end

      resources :replies, only: [:index], module: :activitypub
    end

    resources :followers, only: [:index], controller: :follower_accounts
    resources :following, only: [:index], controller: :following_accounts
    resource :follow, only: [:create], controller: :account_follow
    resource :unfollow, only: [:create], controller: :account_unfollow

    resource :claim, only: [:create], module: :activitypub
    resources :collections, only: [:show], module: :activitypub
    resource :followers_synchronization, only: [:show], module: :activitypub
  end

  get '/@:username', to: 'accounts#show', as: :short_account
  get '/@:username/with_replies', to: 'accounts#show', as: :short_account_with_replies
  get '/@:username/media', to: 'accounts#show', as: :short_account_media
  get '/@:username/tagged/:tag', to: 'accounts#show', as: :short_account_tag
  get '/@:account_username/:id', to: 'statuses#show', as: :short_account_status
  get '/@:account_username/:id/embed', to: 'statuses#embed', as: :embed_short_account_status

  get '/interact/:id', to: 'remote_interaction#new', as: :remote_interaction
  post '/interact/:id', to: 'remote_interaction#create'

  get '/explore', to: 'directories#index', as: :explore
  get '/settings', to: redirect('/settings/profile')

  namespace :settings do
    resource :profile, only: [:show, :update] do
      resources :pictures, only: :destroy
    end

    get :preferences, to: redirect('/settings/preferences/appearance')

    namespace :preferences do
      resource :appearance, only: [:show, :update], controller: :appearance
      resource :notifications, only: [:show, :update]
      resource :other, only: [:show, :update], controller: :other
    end

    resource :import, only: [:show, :create]
    resource :export, only: [:show, :create]

    namespace :exports, constraints: { format: :csv } do
      resources :follows, only: :index, controller: :following_accounts
      resources :blocks, only: :index, controller: :blocked_accounts
      resources :mutes, only: :index, controller: :muted_accounts
      resources :lists, only: :index, controller: :lists
      resources :domain_blocks, only: :index, controller: :blocked_domains
      resources :user_invites, only: :index
      resources :bookmarks, only: :index, controller: :bookmarks
    end

    resources :two_factor_authentication_methods, only: [:index] do
      collection do
        post :disable
      end
    end

    resource :otp_authentication, only: [:show, :create], controller: 'two_factor_authentication/otp_authentication'

    resources :webauthn_credentials, only: [:index, :new, :create, :destroy],
              path: 'security_keys',
              controller: 'two_factor_authentication/webauthn_credentials' do
      collection do
        get :options
      end
    end

    namespace :two_factor_authentication do
      resources :recovery_codes, only: [:create]
      resource :confirmation, only: [:new, :create]
    end

    resources :identity_proofs, only: [:index, :new, :create, :destroy]

    resources :applications, except: [:edit, :index] do
      member do
        post :regenerate
      end
    end

    resource :delete, only: [:show, :destroy]
    resource :migration, only: [:show, :create]

    namespace :migration do
      resource :redirect, only: [:new, :create, :destroy]
    end

    resources :aliases, only: [:index, :create, :destroy]
    resources :sessions, only: [:destroy]
    resources :featured_tags, only: [:index, :create, :destroy]
  end

  resources :media, only: [:show] do
    get :player
  end

  resources :tags, only: [:show]
  resources :emojis, only: [:show]
  resources :invites, only: [:index, :create, :destroy]
  resources :filters, except: [:show, :index]
  resource :relationships, only: [:update]

  # get '/public', to: 'public_timelines#show', as: :public_timeline
  get '/media_proxy/:id/(*any)', to: 'media_proxy#show', as: :media_proxy

  resource :share, only: [:show, :create]

  namespace :admin do
    get '/dashboard', to: 'dashboard#index'

    resources :domain_allows, only: [:new, :create, :show, :destroy]
    resources :domain_blocks, only: [:new, :create, :show, :destroy, :update, :edit]

    resources :email_domain_blocks, only: [:index, :new, :create, :destroy]
    resources :action_logs, only: [:index]
    resources :warning_presets, except: [:new]

    resources :announcements, except: [:show] do
      member do
        post :publish
        post :unpublish
      end
    end

    resource :settings, only: [:edit, :update]
    resources :site_uploads, only: [:destroy]

    resources :invites, only: [:index, :create, :destroy] do
      collection do
        post :deactivate_all
      end
    end

    resources :relays, only: [:index, :new, :create, :destroy] do
      member do
        post :enable
        post :disable
      end
    end

    resources :instances, only: [:index, :show], constraints: { id: /[^\/]+/ } do
      member do
        post :clear_delivery_errors
        post :restart_delivery
        post :stop_delivery
      end
    end

    resources :rules

    resources :reports, only: [:index, :show] do
      member do
        post :assign_to_self
        post :unassign
        post :reopen
        post :resolve
      end

      resources :reported_statuses, only: [:create]
    end

    resources :report_notes, only: [:create, :destroy]

    resources :accounts, only: [:index, :show, :destroy] do
      member do
        post :enable
        post :unsensitive
        post :unsilence
        post :unsuspend
        post :redownload
        post :remove_avatar
        post :remove_header
        post :memorialize
        post :approve
        post :reject
        post :unverify
        post :bot
        post :unbot
      end

      resource :change_email, only: [:show, :update]
      resource :reset, only: [:create]
      resource :action, only: [:new, :create], controller: 'account_actions'
      resources :statuses, only: [:index, :show, :create, :update, :destroy]
      resources :relationships, only: [:index]

      resource :confirmation, only: [:create] do
        collection do
          post :resend
        end
      end

      resource :role, only: [] do
        member do
          post :promote
          post :demote
        end
      end
    end

    resources :pending_accounts, only: [:index] do
      collection do
        post :approve_all
        post :reject_all
        post :batch
      end
    end

    resources :users, only: [] do
      resource :two_factor_authentication, only: [:destroy]
    end

    resources :custom_emojis, only: [:index, :new, :create] do
      collection do
        post :batch
      end
    end

    resources :ip_blocks, only: [:index, :new, :create] do
      collection do
        post :batch
      end
    end

    resources :account_moderation_notes, only: [:create, :destroy]
    resource :follow_recommendations, only: [:show, :update]

    resources :tags, only: [:index, :show, :update] do
      collection do
        post :approve_all
        post :reject_all
        post :batch
      end
    end
  end

  get '/admin', to: redirect('/admin/dashboard', status: 302)

  scope :_ma1sd do
    scope :backend do
      scope :api do
        scope :v1 do
          post '/auth/login', to: 'api/v1/ma1sd/authentication#auth'
          post '/directory/user/search', to: 'api/v1/ma1sd/directory#search'
          post '/identity/single', to: 'api/v1/ma1sd/identity#single'
          post '/identity/bulk', to: 'api/v1/ma1sd/identity#bulk'
          post '/profile/displayName', to: 'api/v1/ma1sd/profile#display_name'
          post '/profile/threepids', to: 'api/v1/ma1sd/profile#threepids'
          post '/profile/roles', to: 'api/v1/ma1sd/profile#roles'
        end
      end
    end
  end

  namespace :api do
    get '/docs', to: 'docs#index'

    # OEmbed
    get '/oembed', to: 'oembed#show', as: :oembed

    # Pleroma endpoints that we are implementing in Mastodon
    namespace :pleroma do
      post :change_password, controller: 'user_settings'
      post :change_email, controller: 'user_settings'
      post :delete_account, controller: 'user_settings'

      scope :accounts, defaults: { format: 'json' } do
        get :mfa, to: 'accounts#mfa'
        scope :mfa do
          scope :setup do
            get :totp, to: 'accounts#setup_totp'
          end
          scope :confirm do
            post :totp, to: 'accounts#confirm_totp'
          end
          get :backup_codes, to: 'accounts#backup_codes'
          delete :totp, to: 'accounts#delete_totp'
        end
      end
    end

    # JSON / REST API
    namespace :v1 do
      resources :statuses, only: [:create, :show, :destroy] do
        scope module: :statuses do
          resources :reblogged_by, controller: :reblogged_by_accounts, only: :index
          resources :favourited_by, controller: :favourited_by_accounts, only: :index
          resource :reblog, only: :create
          post :unreblog, to: 'reblogs#destroy'

          resource :favourite, only: :create
          post :unfavourite, to: 'favourites#destroy'

          resource :bookmark, only: :create
          post :unbookmark, to: 'bookmarks#destroy'

          resource :mute, only: :create
          post :unmute, to: 'mutes#destroy'

          resource :pin, only: :create
          post :unpin, to: 'pins#destroy'
        end

        collection do
          resources :mutes, controller: 'statuses/mutes', only: :index
        end

        member do
          get :context
          get 'context/ancestors', to: 'statuses#ancestors'
          get 'context/descendants', to: 'statuses#descendants', as: 'descendants'
        end
      end

      namespace :timelines do
        resource :home, only: :show, controller: :home
        resource :following, only: :show, controller: :home
        # resource :public, only: :show, controller: :public
        resources :tag, only: :show
        resources :list, only: :show

        resources :group, only: :show do
          resources :tags, only: :show, path: 'tags', controller: 'group_tag'
        end
      end

      namespace :truth do
        namespace :trending do
          resources :truths, only: :index
          resources :groups, only: :index
          resources :group_tags, only: :show
        end

        namespace :admin do
          resources :accounts, only: [:index, :update] do
            post 'mfa/confirm/totp', to: 'accounts#confirm_totp'
          end
          scope :accounts do
            get :blacklist, to: 'accounts#blacklist'
            get :count, to: 'accounts#count'
            get :email_domain_blocks, to: 'accounts#email_domain_blocks'
          end
          resources :email_domain_blocks, only: [:index, :create, :destroy]
          resources :marketing_notifications, only: [:create]
          resources :media_attachments, only: [:destroy]
        end

        scope :password_reset do
          post :confirm, to: 'passwords#reset_confirm'
          post :request, to: 'passwords#reset_request'
        end

        scope :email do
          get :confirm, to: 'emails#email_confirm'
        end

        namespace :carousels do
          resources :avatars, only: [:index] do
            post :seen, on: :collection
          end
          resources :groups, only: [:index] do
            post :seen, on: :collection
          end
          resources :suggestions, only: [:index]
          get 'avatars/accounts/:account_id/statuses', to: '/api/v1/accounts/statuses#index'

          get 'tv',  to: '/api/v1/tv/carousel#index'
          post 'tv/seen', to: '/api/v1/tv/carousel#seen'
        end

        get '/ads', to: 'ads#index', as: :ads
        get '/ads/impression', to: 'ads#impression', as: :ads_impression

        namespace :ios_device_check do
          resources :challenge, only: [:index]
          resources :rate_limit, only: [:index]
          resources :attest, only: [:create] do
            post :baseline, on: :collection
            post :by_key_id, on: :collection
          end
          resources :assert, only: [:create] do
            post :resolve, on: :collection
          end
        end

        namespace :android_device_check do
          resources :challenge, only: [:create]
        end

        resources :chats, only: [:index, :create] do
          scope module: :chats do
            resources :messages, only: [:index, :create, :destroy]
          end
        end

        namespace :policies do
          get :pending
          patch :accept, path: '/:policy_id/accept', to: 'policies/accept'
        end

        resources :oauth_tokens, only: [:index, :destroy]

        namespace :suggestions do
          resources :groups, only: [:index, :destroy]

          namespace :follows do
            post :create, path: ':account_id', to: 'suggestions/follows'
          end

          namespace :statuses do
            post :create, path: ':account_id', to: 'suggestions/statuses'
          end
        end

        resources(:videos, only: :show)
      end

      namespace :pleroma do
        namespace :chats do
          post :by_account_id, path: 'by-account-id/:account_id'
          get :by_account_id, path: 'by-account-id/:account_id', to: '/api/v1/pleroma/chats#get_by_account_id'
          get 'silences', to: 'silences#index'
          get 'sync'
          get 'events', to: 'events#index'
          get 'search', to: 'search#index'
          get 'search/messages', to: 'search#search_messages'
          get 'search/previews', to: 'search#search_previews'
        end

        resources :chats, only: [:index, :destroy, :show, :update] do
          post 'read', to: 'chats#mark_read'
          post 'accept', to: 'chats#accept'

          scope module: :chats do
            get 'sync', to: 'messages#sync'
            resources :messages, only: [:index, :destroy, :create, :show] do
              resources :reactions, only: [:show, :create, :destroy], param: :emoji
            end
            post 'silences', to: 'silences#create'
            delete 'silences', to: 'silences#destroy'
            get 'silences', to: 'silences#show'
          end
        end
      end

      resources :streaming, only: [:index]
      resources :custom_emojis, only: [:index]
      resources :suggestions, only: [:index, :destroy]
      resources :scheduled_statuses, only: [:index, :show, :update, :destroy]
      resources :preferences, only: [:index]

      resources :announcements, only: [:index] do
        scope module: :announcements do
          resources :reactions, only: [:update, :destroy]
        end

        member do
          post :dismiss
        end
      end

      # namespace :crypto do
      #   resources :deliveries, only: :create

      #   namespace :keys do
      #     resource :upload, only: [:create]
      #     resource :query,  only: [:create]
      #     resource :claim,  only: [:create]
      #     resource :count,  only: [:show]
      #   end

      #   resources :encrypted_messages, only: [:index] do
      #     collection do
      #       post :clear
      #     end
      #   end
      # end

      resources :conversations, only: [:index, :destroy] do
        member do
          post :read
        end
      end

      resources :media, only: [:create, :update, :show]
      resources :blocks, only: [:index]
      resources :mutes, only: [:index]
      resources :favourites, only: [:index]
      resources :bookmarks, only: [:index]
      resources :reports, only: [:create]
      resources :trends, only: [:index]
      resources :filters, only: [:index, :create, :show, :update, :destroy]
      resources :endorsements, only: [:index]
      resources :markers, only: [:index, :create]

      namespace :apps do
        get :verify_credentials, to: 'credentials#show'
      end

      resources :apps, only: [:create]

      namespace :emails do
        resources :confirmations, only: [:create]
      end

      resource :instance, only: [:show] do
        resources :peers, only: [:index], controller: 'instances/peers'
        resource :activity, only: [:show], controller: 'instances/activity'
        resources :rules, only: [:index], controller: 'instances/rules'
      end

      resource :domain_blocks, only: [:show, :create, :destroy]
      resource :directory, only: [:show]

      resources :follow_requests, only: [:index] do
        member do
          post :authorize
          post :reject
        end
      end

      resources :notifications, only: [:index, :show] do
        collection do
          post :clear
        end

        member do
          post :dismiss
        end
      end

      namespace :accounts do
        get :verify_credentials, to: 'credentials#show'
        patch :update_credentials, to: 'credentials#update'
        get :chat_token, to: 'credentials#chat_token'
        resource :search, only: :show, controller: :search
        resource :lookup, only: :show, controller: :lookup
        resources :relationships, only: :index
      end

      resources :accounts, only: [:show] do
        resources :statuses, only: :index, controller: 'accounts/statuses'
        resources :followers, only: :index, controller: 'accounts/follower_accounts'
        resources :following, only: :index, controller: 'accounts/following_accounts'
        resources :lists, only: :index, controller: 'accounts/lists'
        resources :identity_proofs, only: :index, controller: 'accounts/identity_proofs'
        resources :featured_tags, only: :index, controller: 'accounts/featured_tags'

        member do
          post :follow
          post :unfollow
          post :block
          post :unblock
          post :mute
          post :unmute
        end

        resource :pin, only: :create, controller: 'accounts/pins'
        post :unpin, to: 'accounts/pins#destroy'
        resource :note, only: :create, controller: 'accounts/notes'
      end

      resources :lists, only: [:index, :create, :show, :update, :destroy] do
        resource :accounts, only: [:show, :create, :destroy], controller: 'lists/accounts'
      end

      namespace :groups do
        resources :relationships, only: [:index]
        resources :tags, only: [:index]
      end

      get '/groups/mutes', to: 'groups/mutes#index'

      resources :groups, only: [:index, :create, :show, :update, :destroy] do
        post :mute, to: 'groups/mutes#create'
        post :unmute, to: 'groups/mutes#destroy'

        resources :memberships, only: [:index], controller: 'groups/memberships'

        resources :membership_requests, only: [:index], controller: 'groups/membership_requests' do
          member do
            post :authorize, to: 'groups/membership_requests#accept'
            post :reject
          end
          post 'resolve', on: :collection
        end

        resources :statuses, only: [:destroy], controller: 'groups/statuses' do
          resource :pin, only: :create, controller: 'groups/statuses/pins'
          post :unpin, to: 'groups/statuses/pins#destroy'
        end

        resource :blocks, only: [:show, :create, :destroy], controller: 'groups/blocks'

        resources :tags, only: :update, controller: 'groups/tags'

        member do
          post :join
          post :leave
          post :promote
          post :demote
        end

        collection do
          get :search
          get :lookup
          get :validate
        end
      end

      resources :tags, only: [:show] do
        resources :groups, only: :index, controller: 'tags/groups'
      end

      namespace :featured_tags do
        get :suggestions, to: 'suggestions#index'
      end

      resources :featured_tags, only: [:index, :create, :destroy]

      resources :polls, only: [:create, :show] do
        resources :votes, only: :create, controller: 'polls/votes'
      end

      namespace :push do
        resource :subscription, only: [:create, :show, :update, :destroy]
      end

      namespace :tv do
        resources :channels, only: :index
        get 'accounts/:id/status', to: 'accounts#show'
        get 'epg/:name', to: 'programme_guides#show'
        get 'channels/:id/guide', to: 'guide#show'
        put 'channels/:id/remind', to: 'program_reminder#update'
        delete 'channels/:id/remind', to: 'program_reminder#destroy'
      end

      get '/stats', to: 'admin#stats'
      namespace :admin do
        resources :statuses, only: [:index, :show] do
          post :desensitize
          post :discard
          post :privatize
          post :publicize
          post :sensitize
          post :undiscard
        end

        resources :accounts, only: [:index, :show, :create, :update, :destroy] do
          resources :follows, only: [:show], param: :target_account_id, controller: 'accounts/follows'
          resources :statuses, only: [:index], controller: 'accounts/statuses'
          resources :webauthn_credentials, only: [:index], controller: 'accounts/webauthn_credentials'

          collection do
            post :bulk_approve
          end

          member do
            post :enable
            post :unsensitive
            post :unsilence
            post :unsuspend
            post :approve
            post :reject
            post :verify
            post :unverify
            post :role
          end

          resource :action, only: [:create], controller: 'account_actions'
        end

        post '/accounts/bulk_action', to: 'bulk_account_actions#create'

        resources :groups, only: [:index, :show, :update, :destroy] do
          get :search, on: :collection
          resources :statuses, only: [:index], controller: 'groups/statuses'
        end

        resources :reports, only: [:index, :show] do
          member do
            resources :moderation_records, only: [:index]
            post :assign_to_self
            post :unassign
            post :reopen
            post :resolve
          end
        end

        resources :trending_statuses, only: :index do
          member do
            put :include
            put :exclude
          end

          collection do
            resources :settings, param: :name, controller: 'trending_statuses/settings', only: [:index, :update]
          end

          collection do
            resources :expressions, controller: 'trending_statuses/expressions', only: [:index, :create, :update, :destroy]
          end
        end

        resources :trending_tags, only: [:index, :update]

        resources :trending_groups, only: :index do
          member do
            put :include
            put :exclude
          end

          get :excluded, on: :collection
        end

        resources :chat_messages, only: [:show, :destroy]

        resources :policies, only: [:index, :create, :destroy]

        namespace :truth do
          resources :interactive_ads, only: :create
          namespace :suggestions do
            resources :groups, only: [:index, :show, :create, :destroy]
          end

          namespace :android_device_check do
            resources :integrity, only: [:create]
          end

          namespace :ios_device_check do
            resources :attest, only: [:create]
          end
        end

        namespace :tv do
          resources :sessions, only: :index
        end

        resources :tags, only: [:index, :update]
        resources :registrations, only: [:create]
        resources :links, only: [:update]
      end

      resources :feeds, only: [
        :index,
        # :create,
        :show,
        :update,
        # :destroy
      ] do
        member do
          post 'accounts/:account_id', to: 'feeds#add_account'
          delete 'accounts/:account_id', to: 'feeds#remove_account'
          patch :seen, to: 'feeds#seen'
        end
      end

      namespace :recommendations do
        namespace :accounts do
          resources :suppressions, only: [:create, :destroy]
        end
        namespace :groups do
          resources :suppressions, only: [:create, :destroy]
        end
      end

      namespace :verify_sms do
        resources :countries, only: :index
      end

      namespace :push_notifications do
        post '/:mark_id/mark', to: 'analytics#mark', as: :analytics_mark
      end
    end

    namespace :v2 do
      resources :media, only: [:create]
      get '/search', to: 'search#index', as: :search
      resources :suggestions, only: [:index, :destroy]

      namespace :pleroma do
        namespace :chats do
          get 'events', to: 'events#index'
        end
      end

      resources :statuses, only: [:show] do
        member do
          get 'context/ancestors', to: 'statuses#ancestors', as: 'ancestors'
          get 'context/descendants', to: 'statuses#descendants', as: 'descendants'
        end
      end

      resources :feeds, only: [:index]
    end

    namespace :v4 do
      namespace :truth do
        get '/ads', to: 'ads#index'
      end
    end

    namespace :web do
      resource :settings, only: [:update]
      resource :embed, only: [:create]
      resources :push_subscriptions, only: [:create] do
        member do
          put :update
        end
      end
    end

    namespace :mock do
      get '/feeds', to: 'feeds#index'
      post '/feeds', to: 'feeds#create'
      get '/feeds/:id', to: 'feeds#show'
      patch '/feeds/:id', to: 'feeds#update'
      delete '/feeds/:id', to: 'feeds#destroy'
      put '/feeds/sort', to: 'feeds#sort'
      post '/feeds/:id/accounts/:account_id', to: 'feeds#add_account'
      delete '/feeds/:id/accounts/:account_id', to: 'feeds#remove_account'
      post '/feeds/groups/:group_id/unmute', to: 'feeds#unmute_group'
      post '/feeds/groups/:group_id/mute', to: 'feeds#mute_group'
    end
  end

  get '/api/v2/pleroma/chats', to: 'api/v1/pleroma/chats#index'
  get '/api/v1/truth/trends/groups', to: 'api/v1/truth/trending/groups#index'
  get '/api/v1/truth/trends/groups/:id/tags', to: 'api/v1/truth/trending/group_tags#show', as: :truth_trends_groups

  get '/api/oauth_tokens', to: 'api/v1/truth/oauth_tokens#index'
  delete '/api/oauth_tokens/:id', to: 'api/v1/truth/oauth_tokens#destroy'

  get '/api/v1/trends/statuses', to: 'api/v1/truth/trending/truths#index'

  get '/web/(*any)', to: 'home#index', as: :web

  get '/about', to: 'about#show'
  get '/about/more', to: 'about#more'
  get '/terms', to: 'about#terms'

  match '/', via: [:post, :put, :patch, :delete], to: 'application#raise_not_found', format: false
  match '*unmatched_route', via: :all, to: 'application#raise_not_found', format: false
end
