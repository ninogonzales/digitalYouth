class WelcomeController < ApplicationController
  def index
  end

  def signup_jobseeker
  end

  def signup_employer
  end

  def lost_email

  end

  def send_lost_email
  	if ContactMailer.lost_email(params[:user][:email], params[:user][:first_name], params[:user][:last_name], params[:user][:message]).deliver_now
  		flash["notice"] = "Thank you for your request.  An administrator will look into it and contact you."
  	else
  		flash[:error] = "Your request couldn't be sent."
  	end
  	redirect_back_or root_path
  end

  helper_method :resource_name, :resource, :devise_mapping

  def resource_name
    :user
  end
 
  def resource
    @resource ||= User.new
  end
 
  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end
end
