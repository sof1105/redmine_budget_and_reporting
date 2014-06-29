class TargetHoursController < ApplicationController

	def index
		user = params[:user_id]
		issue = params[:issue_id]
		hours = params[:hours]
		@errors = []
		
		unless user && User.find(user)
			@errors << "User wurde nicht gefunden"
			return
		end
		
		unless issue && Issue.find(issue)
			@errors << "Issue wurde nicht gefunden"
			return
		end
		
	end
	
	def create
	
	end
	
	def delete
	
	end
	
	def update
	
	end

end
