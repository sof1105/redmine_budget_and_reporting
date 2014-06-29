class WeekeffortController < ApplicationController

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
	
	def update
	
	end
	
	def delete
		if params[:id] && Weekeffort.find(params[:id]) && User.cu
			
		end
	end
	
end
