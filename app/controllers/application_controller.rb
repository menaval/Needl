class ApplicationController < ActionController::Base
  before_action :authenticate_user!, unless: :pages_controller?
  # on laisse unless pages_controller au cas ou pour l'instant
  # include Pundit

  protect_from_forgery with: :exception
  before_filter :configure_permitted_parameters, if: :devise_controller?

  # after_action :verify_authorized, except:  :index, unless: :devise_or_pages_controller?
  # after_action :verify_policy_scoped, only: :index, unless: :devise_or_pages_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:account_update) << :name
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
end
