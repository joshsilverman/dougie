class AuthenticationsController < ApplicationController

  before_filter :authenticate_user!, :except => ["create"]

  def create
    omniauth = request.env["omniauth.auth"]
    omniauth = session[:omniauth] if omniauth.nil?

    # try to load email into omniauth hash
    if omniauth.nil?
      flash[:error] = "There was an error while setting up that authentication."
      redirect_to "/users/sign_up"
      return
    elsif omniauth['user_info']['email'].nil?
      begin
        omniauth['user_info']['email'] = params[:user][:email] if params[:user]
      rescue
      end
      begin
        omniauth['user_info']['email'] = omniauth['extra']['user_hash']['email'] if omniauth['extra']
      end
    end

    authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])
    if authentication
      # flash[:notice] = "Signed in successfully."
      sign_in(:user, authentication.user)
      redirect_to "/"
    elsif current_user
      current_user.authentications.create!(:provider => omniauth['provider'], :uid => omniauth['uid'])
      flash[:notice] = "Authentication successful."
      redirect_to "/"
    else
      @resource = User.new
      @resource.apply_omniauth(omniauth)
      @resource.skip_confirmation! unless params and params[:user] and params[:user][:email]
      if @resource.save
        sign_in(:user, @resource)
        flash[:notice] = "Account successfully created. Welcome!"
        redirect_to "/explore"
      else

        #log failed account creation if due to email already taken
        if @resource.errors['email'].include?("has already been taken")
          auth_logger.info("\n\"Email has already been taken\"\n#{Time.now.to_s(:db)}\nemail: #{@resource.email}\n")
          @resource.password = ""
          puts @resource.to_yaml
          render "/registrations/new"
        elsif @resource.errors['email'].include?("can't be blank")
          session[:omniauth] = omniauth.except('extra')
          redirect_to "/users/get_email"
        end
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
