class AuthenticationsController < ApplicationController

  before_filter :authenticate_user!, :except => ["create"]

  def create
    omniauth = request.env["omniauth.auth"]
    authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])
    if authentication
      flash[:notice] = "Signed in successfully."
      sign_in(:user, authentication.user)
      redirect_to "/"
    elsif current_user
      current_user.authentications.create!(:provider => omniauth['provider'], :uid => omniauth['uid'])
      flash[:notice] = "Authentication successful."
      redirect_to "/"
    else
      user = User.new
      user.apply_omniauth(omniauth)
      if user.save
        flash[:notice] = "Signed in successfully."
        sign_in(:user, user)
        redirect_to "/users/edit"
      else
        if not user.errors['email'].blank? and user.errors['email'].include?("has already been taken")

          #log failed account creation
          auth_logger.info("\n#{Time.now.to_s(:db)}\nemail: #{user.email}\n")

        end

        session[:omniauth] = omniauth.except('extra')
        session[:omniauth]['user_info']['email'] = omniauth['extra']['user_hash']['email'] if omniauth['extra']

        redirect_to "/users/sign_up"
      end
    end
  end

  def destroy
    @authentication = current_user.authentications.find_by_id(params[:id])
    if @authentication
      @authentication.destroy
      notice = "Successfully destroyed authentication."
    else
      notice = "There was an error while deleting that authentication."
    end
    redirect_to "/users/edit", :notice => notice
  end

  def auth_logger
    @@auth_logger ||= Logger.new("#{RAILS_ROOT}/log/auth_err.log")
  end
end
