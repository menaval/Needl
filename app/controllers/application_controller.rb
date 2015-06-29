class ApplicationController < ActionController::Base
  include PublicActivity::StoreController
  before_action :authenticate_user!, unless: :pages_controller?
  before_action :count_notifs
  before_action :tracking
  before_action :welcome_by_ceo
  before_action :correct_user

  # on laisse unless pages_controller au cas ou pour l'instant
  # include Pundit

  protect_from_forgery with: :exception
  before_filter :configure_permitted_parameters, if: :devise_controller?

  # after_action :verify_authorized, except:  :index, unless: :devise_or_pages_controller?
  # after_action :verify_policy_scoped, only: :index, unless: :devise_or_pages_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized


  protected

  def count_notifs
    if user_signed_in?
      activities = PublicActivity::Activity.where(owner_id: current_user.my_friends_ids, owner_type: 'User').order('created_at DESC').limit(20)
      @notification_count = activities.where(read: false).first == nil ? 0 : activities.where(read: false).count
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:account_update) << :name
  end

  def correct_user
    # exclure charles lucas
    if current_user && current_user.id == 101
        redirect_to "http://s3.amazonaws.com/rapgenius/huggy_les_bons_tuyaux.jpg"
      end
  end

  def welcome_by_ceo
    if current_user && current_user.sign_in_count == 1
      Friendship.create(sender_id: 125, receiver_id: current_user.id, accepted: true)
    end
  end

  private

  def devise_or_pages_controller?
    devise_controller? || pages_controller?
  end

  def pages_controller?
    controller_name == "pages"  # Brought by the `high_voltage` gem
  end

  def user_not_authorized
    flash[:error] = I18n.t('controllers.application.user_not_authorized', default: "You can't access this page.")
    redirect_to(root_path)
  end

  def tracking
    @tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
  end

end
