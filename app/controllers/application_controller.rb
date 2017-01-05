class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user
  helper_method :user_signed_in?
  helper_method :correct_user?
  helper_method :is_instructor?

  private
    def current_user
      begin
        @current_user ||= User.find(session[:user_id]) if session[:user_id]
      rescue Exception => e
        nil
      end
    end

    def user_signed_in?
      return true if current_user
    end

    def correct_user?
      @user = User.find(params[:id])
      unless current_user == @user
        redirect_to root_url, :alert => "Access denied."
      end
    end

    def authenticate_user!
      if !current_user
        redirect_to root_url, :alert => 'You need to sign in for access to this page.'
      end
    end

    def is_instructor?(user=nil)
      user = user || current_user
      return true if user and \
                     Setting.instructors and \
                     Setting.instructors.include? user.username
    end

    def anon_octokit
      Octokit::Client.new \
        :client_id => ENV['OMNIAUTH_PROVIDER_KEY'],
        :client_secret => ENV['OMNIAUTH_PROVIDER_SECRET']
    end

    def machine_octokit
      Octokit::Client.new \
        :access_token => ENV['MACHINE_USER_KEY']
    end

    def session_octokit
      token = session['oauth_token'] || ""
      if token == ""
        raise "You must be signed in"
      end
      Octokit::Client.new \
        :access_token => token
    end
end
