class JobPostingsController < ApplicationController

	before_action :authenticate_user!, except: [:show, :index]
	before_action :check_employer, except: [:show, :index,:refresh,:refresh_process]
	before_action :check_admin	 , only: [:refresh,:refresh_process]
	before_action :job_owner	 , only: [:edit, :update, :destroy]
	before_action :check_fields	 , only: [:create, :update]

	def index # Job Postings landing page
		if params[:user].nil?
			@job_postings = JobPosting.all.order(views: :desc).limit(10)
			@reccommended_job_postings = reccomended_jobs
		else
			@job_postings = JobPosting.where(user_id: params[:user])
			@company = User.find(params[:user])
		end
	end
	
	def show # Shows a specific job posting and its skills
		@job_posting = JobPosting.includes(:user,:job_category).find(params[:id])
		@company_name = @job_posting.company_name.nil? ? @job_posting.user.company_name : @job_posting.company_name
		@req_skills  = JobPostingSkill.where(job_posting_id:params[:id], importance: 2).includes(:skill).order(:id)
		@pref_skills = JobPostingSkill.where(job_posting_id:params[:id], importance: 1).includes(:skill).order(:id)
		add_view(@job_posting)
	end

	def new # Creates the form to make a new job posting
		@job_posting = JobPosting.new
		job_posting_skills = @job_posting.job_posting_skills.build
		job_posting_skills.skill = Skill.new
		@questions = Question.get_label_map
		@categories = JobCategory.all
		@job_types = JobPosting.get_types_collection
	end

	def create # Creates a new job posting and skills
		params[:job_posting][:user_id] = current_user.id
		
		@job_posting = JobPosting.new(job_posting_params)
		if @job_posting.save && @job_posting.process_skills(params[:job_posting]["job_posting_skills_attributes"])
			redirect_to job_postings_path, flash: {success: "Job Posting Created!"}
			JobPosting.reindex if !Rails.env.test?
		else
			flash[:warning] = "Oops, there was an issue in creating your Job Posting."
			redirect_back_or job_postings_path
		end
	end

	def edit # Creates the form to edit a job posting
		@job_posting_skills = JobPostingSkill.where(job_posting_id:params[:id]).order(:id)
		@questions = Question.get_label_map
		@categories = JobCategory.all
		@job_types = JobPosting.get_types_collection
	end

	def update # Updates the job posting
		if @job_posting.update_attributes(job_posting_params) && @job_posting.process_skills(params[:job_posting]["job_posting_skills_attributes"])
			redirect_to job_postings_path, flash: {success: "Job Posting Updated!"}
			JobPosting.reindex if !Rails.env.test?
		else
			flash[:warning] = "Oops, there was an issue in editing your Job Posting."
			redirect_back_or edit_job_posting_path
		end
	end

	def destroy # Deletes the job posting from the database
		if @job_posting.destroy
			JobPosting.reindex if !Rails.env.test?
			redirect_to job_postings_path, flash: {success: "Job Posting Deleted!"}
		else
			flash[:danger] = 'There was an error while deleting your Job Posting.'
			redirect_back_or job_postings_path
		end
	end

	def refresh
		# Page to display the upload form for auto populating job postings
	end

	def refresh_process	# Takes in a .rb file and runs the file to refresh the auto populated job postings
		if !params[:job_posting_seeds].nil? and !params[:job_posting_seeds].tempfile.nil?
			puts "Deleting data.."
			ActiveRecord::Base.transaction do
				silence_stream(STDOUT) do
					@job_postings = JobPosting.where("company_name IS NOT NULL")
					@ids = @job_postings.pluck(:id)
					@job_postings.delete_all
					JobPostingSkill.where(job_posting_id: @ids).delete_all
				end
			end
			puts "Inserting data.."
			ActiveRecord::Base.transaction do
				silence_stream(STDOUT) do
					load params[:job_posting_seeds].tempfile
				end
			end
			JobPosting.reindex
			puts "Completed."
			redirect_to root_path, flash: {success: "Refreshed Auto Populated Job Postings"}
		else
			redirect_to refresh_job_posting_path, flash: {success: "Need to upload a file"}
		end
	end

private
	def job_posting_params # Restricts parameters
		params.require(:job_posting).permit(:title, :location, :pay_range, :link, :job_category_id, :posted_by, :description, :open_date, :close_date, :user_id, :job_type)
	end

	def reccomended_jobs
		if user_signed_in? && current_user.has_role?(:employee)
			# Viewed Job Postings Query:
			#  Does not currently take into account the time spent on a page, or the age of the view
			#  Limits the views to be newer than a year
			#  ----------------------------------------
			#  Can improve the recommendation system by:
			#   Improving the selection weighting of time spent on a page vs its age
			#   Could also count the number of times a page view occurs and weight it by that too
			#   Limit to n number of job postings to use as the recommendation
			viewed_job_postings = ActiveRecord::Base.connection.execute("
						SELECT substring(properties->>'page', '[^/]*$') AS id 
						FROM ahoy_events 
						WHERE name = '$view_end' 
						  AND visit_id IN (SELECT visit_id FROM ahoy_events WHERE user_id = #{current_user.id})
						  AND properties ->> 'page' LIKE '/job_postings/%'
						  AND time > NOW() - INTERVAL '1 years'
						").values.flatten # Does not currently take into account the times on each page or much of the age, could order by time spent on a page and limit results
			corpus = Array.new
			corpus << viewed_job_postings if !viewed_job_postings.empty?

			if !corpus.empty?
				corpus = JobPosting.find(corpus)
				corpus_arr = Array.new 
				#Add the viewed jobpostings to the corpus in the correct format
				corpus.each do |v|  
					corpus_arr.push({index: JobPosting.searchkick_index.name,id: v.id})
				end
				
				# Add the list of user_skills the user has entered to the corpus
				# Can be removed if needed. Added to try to make the recommendations closer to the users potential preferences
				corpus_arr.push(current_user.skills.pluck(:name))
				
				results = JobPosting.search more_like_this: {
									fields: [:title,:company_name,:location,:pay_range,:link,:posted_by,:job_type,:description,:open_date,:close_date,:job_category_id],
									like: corpus_arr,
									min_term_freq: 1,
									stop_words: get_stop_word_array
						        }, per_page: 10
			end

			return results
		else 
			return nil
		end
	end

	# This method should be moved to a more general class or location (Don't know the best place to put it)
	def get_stop_word_array
		return ['a','about','above','after','again','against','all','am','an','and','any','are',"aren't",'as','at','be','because','been','before','being','below','between','both','but','by',
				"can't",'cannot','could',"couldn't",'did',"didn't",'do','does',"doesn't",'doing',"don't",'down','during','each','few','for','from','further','had',"hadn't",'has',"hasn't",
				'have',"haven't",'having','he',"he'd","he'll","he's",'her','here',"here's",'hers','herself','him','himself','his','how',"how's",'i',"i'd","i'll","i'm","i've",'if','in','into',
				'is',"isn't",'it',"it's",'its','itself',"let's",'me','more','most',"mustn't",'my','myself','no','nor','not','of','off','on','once','only','or','other','ought','our','ours',
				'ourselves','out','over','own','same',"shan't",'she',"she'd","she'll","she's",'should',"shouldn't",'so','some','such','than','that',"that's",'the','their','theirs','them',
				'themselves','then','there',"there's",'these','they',"they'd","they'll","they're","they've",'this','those','through','to','too','under','until','up','very','was',"wasn't",
				'we',"we'd","we'll","we're","we've",'were',"weren't",'what',"what's",'when',"when's",'where',"where's",'which','while','who',"who's",'whom','why',"why's",'with',"won't",
				'would',"wouldn't",'you',"you'd","you'll","you're","you've",'your','yours','yourself','yourselves','zero']
	end

	def check_employer # Checks current user is an employer
		if !current_user.has_role? :employer
			flash[:warning] = 'You are not an employer!'
			redirect_back_or current_user
		end
	end

	def check_admin # Checks current user is an admin
		if !current_user.has_role? :admin
			flash[:danger] = 'Admins only.'
			redirect_back_or current_user
		end
	end

	def job_owner # Checks current user is the Job Posting owner
		@job_posting = JobPosting.find(params[:id])
		if @job_posting.user_id != current_user.id
			flash[:danger] = 'You can only make changes to your Job Posting'
			redirect_back_or current_user
		else
			return @job_posting
		end
	end

	def add_view(job_posting) # Checks to make sure the user doesn't own the posting and hasn't seen it this session
		return nil if (user_signed_in? && @job_posting.user_id == current_user.id)||(job_posting.is_expired?)
		session[:job_posting_views] = Array.new if session[:job_posting_views].nil?
		if !session[:job_posting_views].include? job_posting.id
			job_posting.update(views: @job_posting.views+1)
			session[:job_posting_views].push(job_posting.id)
		end
	end

	def check_fields # Performs rigorous checks to ensure that the job posting is valid
		args = params[:job_posting]
		if args[:title].blank? || args[:location].blank? || args[:description].blank? || args[:open_date].blank? || args[:close_date].blank? || args[:job_category_id].blank? || args[:job_type].blank?
			flash[:warning] = "Missing required fields"
		elsif args[:location].split(',').length != 2 || args[:location].split(',')[1].strip.length != 2
			flash[:warning] = "Location must in the form: City , Province Code"
		elsif args[:open_date] > args[:close_date]
			flash[:warning] ="Open date must be before close date"
		elsif args["job_posting_skills_attributes"].nil?
			flash[:warning] = "You must enter some skills associated with this job."
		elsif !args["job_posting_skills_attributes"].nil?
			destroy = true
			missing = false
			args["job_posting_skills_attributes"].each do |m|
				missing = true if m[1]["skill_attributes"]["name"].blank?
				missing = true if m[1]["question_id"].blank?
				missing = true if m[1]["importance"].blank?
				destroy = false if m[1]["_destroy"] == "false"
			end
			flash[:warning] = "You must enter all skill fields." if missing
			flash[:warning] = "You must enter some skills associated with this job." if destroy
		end
		redirect_back_or job_postings_path if !flash[:warning].blank?
	end
end