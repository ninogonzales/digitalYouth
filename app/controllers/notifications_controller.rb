class NotificationsController < ApplicationController

	before_action :authenticate_user!
	before_action :notification_owner, only: [:update, :delete, :trackable]

	respond_to :js # Formating for the AJAX requests
	respond_to :html, only: :index

	def index # Get all notifications, paginates to 20
		@activities = get_notifications.paginate(page: params[:page], per_page: 20)
	end

	def show # Get 6 notifications first, then get one and offset the page
		params[:page] = 1 if params[:page].nil?
		if Integer(params[:page]) > 1
			params[:page] = Integer(params[:page]) + 6
			@dropdown_activities = get_notifications.paginate(page: params[:page], per_page: 1)
		else
			@dropdown_activities = get_notifications.paginate(page: params[:page], per_page: 6)
		end
	end

	def update # Mark the notification as read
		@notification.update(is_read: true)
	end

	def delete # Delete the notification
		@notification.delete
	end

	def update_all # Mark all notifications as read
		@activities = update_notifications
	end

	def delete_all # Delete all notifications
		PublicActivity::Activity.where(owner_id: current_user.id, owner_type: "User").delete_all
	end

	def trackable # Mark read, redirect to trackable page
		@notification.update(is_read: true)
		redirect_to polymorphic_path(@notification.trackable)
	end

private
	def notification_owner # Verifies the user owns the notification
		@notification = PublicActivity::Activity.find(params[:id])
		if @notification.owner_type != "User" || @notification.owner_id != current_user.id
			redirect_to user_path(current_user) , flash: {danger: "You do not own that notification."}
		else
			return @notification
		end
	end

	def get_notifications # Retrieves a users notifications and marks as seen
		rst = PublicActivity::Activity.order("created_at desc").where(owner_id: current_user.id, owner_type: "User").includes(:trackable)
		rst.update_all(is_seen: true) if @notif_unseen.is_a? Integer # if all notifications are seen, this @notif_unseen "", else they are all updated
		return rst
	end

	def update_notifications # Retrieves a users notifications and marks as read
		rst = PublicActivity::Activity.order("created_at desc").where(owner_id: current_user.id, owner_type: "User").includes(:trackable)
		rst.update_all(is_read: true)
		return rst
	end
end
