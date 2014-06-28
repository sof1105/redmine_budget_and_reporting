class TargetHoursController < ApplicationController

	def index
		u = params[:user_id]
		i = params[:issue_id]
		@errors = []
		
		unless u && User.find(u)
			@errors << "User wurde nicht gefunden"
			return
		end
		
		unless i && Issue.find(i)
			@errors << "Issue wurde nicht gefunden"
			return
		end
		
		
	end


end
