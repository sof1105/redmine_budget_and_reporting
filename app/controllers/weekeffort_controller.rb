#encoding: utf-8

class WeekeffortController < ApplicationController

	def index
		offset = 0
		errors = []
		
		unless params[:issue_id] && issue = Issue.find(params[:issue_id])
			errors << "Issue wurde nicht gefunden"
			render :partial => "overview", :locals => {:errors => errors}
			return
		end
		
		if params[:user_id] && !(user = User.find(params[:user_id]))
			errors << "Benutzer nicht gefunden"
			render :partial => "overview", :locals => {:errors => errors}
			return
		elsif not params[:user_id] && !(user = issue.assigned_to)
			errors << "Bislang kein Benutzer zugeordnet"
			render :partial => "overview", :locals => {:errors => errors}
			return
		end
		
		
		if params[:offset]
			offset = params[:offset] == params[:offset].to_i.to_s ? params[:offset].to_i : 0
		end
		
		render :partial => "overview", :locals => {:issue_id => issue, :user_id => user}
	end
	
	def update
	
	end
	
	def delete
		if params[:id] && Weekeffort.find(params[:id]) && User.current.admin?
			Weekeffort.destroy(params[:id])
		end
		
		redirect_to :action => "index"
	end
	
end
