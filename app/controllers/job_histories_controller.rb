class JobHistoriesController < ApplicationController

  before_action :authenticate_user!
  before_action :job_histories_owner, only: [:edit, :update, :destroy]
  #before_action :check_fields, only: [:update, :create]

#route errors from :job_histories_owner, index no longer displaying content reloading after adding check fields, when all r full believes one is empty userid not being set in test same as in create below

  def index
	@job_history = JobHistory.where(user_id: current_user.id)
	@user=current_user
  end
  def show

  end

  def new
	@user=current_user
	@job_histories = JobHistory.new
         
  end

  def create
	#Not working added hidden field back
	params[:job_history][:user_id]=current_user.id


	@job_histories = JobHistory.new(job_history_params)
	if @job_histories.save
		redirect_to job_histories_path , flash: {success: "Thank you for adding to your Job History!"}
	else
		redirect_to job_histories_path , flash: {danger: "There was a problem in saving your Job History!"}
	end
  end



  def edit
	@user=current_user
	@job_history = JobHistory.find(params[:id])
  end

  def update
	@job_history = JobHistory.find(params[:id])

	if @job_history.update(job_history_params)
		flash[:success]="Thank you for updating to your Job History!"
		redirect_to job_histories_path
	else
		flash[:danger]="There was a problem in updating your Job History!"
		redirect_back_or edit_job_history_path(@job_history)
	end
  end

  def destroy
	if JobHistory.find(params[:id])
		JobHistory.find(params[:id]).destroy
		redirect_to job_histories_path , flash: {success: "Successfully Deleted."}
	else
		redirect_to job_histories_path , flash: {danger: "Your Job Did Not Delete Successfully."}
	end
  end
  
private
def job_history_params
	params.require(:job_history).permit(:user_id, :employer, :position, :start_date, :description, :skills)
  end 

def job_histories_owner
		@job_history = JobHistory.find(params[:id])

		if @job_history.user_id != current_user.id
			flash[:danger] = 'Access denied as you are not owner of this Job History'
			redirect_to current_user
		else
			return @job_histories
		end
	end
end



def check_fields
	args=params[:job_history]
	if args[:start_date].blank? || args[:employer].blank? || args[:position].blank? || args[:description].blank? || args[:skills].blank?
		flash[:warning]="Missing Required Fields"
		redirect_back_or job_histories_path
	end
end
