class RegistrationsController < Devise::RegistrationsController

  # POST /resource/sign_up
  def create
    build_resource

    if resource.save
      set_flash_message :notice, :signed_up

      # check if confirmation token set
      if (resource[:confirmation_token])
        flash[:notice] = "An email has been sent to your account. Please confirm your account to complete your sign up process."
        redirect_to "/users/welcome"

      # attempt sign-in if no confirmation token
      else
        sign_in(resource_name, resource)
      end
    else

      if not resource.errors.email.nil?

        #log failed account creation
        account_logger.info("\n#{Time.now.to_s(:db)}\nemail: #{resource.email}\n#{resource.errors}\n")
        
      end

      clean_up_passwords(resource)
      render_with_scope :new
    end

    session[:omniauth] = nil unless @user.new_record?
  end

  def build_resource(*args)
    super
    if session[:omniauth]
      @user.apply_omniauth(session[:omniauth])
      @user.valid?
    end
  end

  def edit
    @authentications = current_user.authentications.all
    super
  end

  def account_logger
    @@account_logger ||= Logger.new("#{RAILS_ROOT}/log/account_create.log")
  end

end