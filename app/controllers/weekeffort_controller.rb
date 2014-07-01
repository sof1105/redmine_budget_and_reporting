#encoding: utf-8

class WeekeffortController < ApplicationController

	before_filter :validate_params

	def index
		offset = 0
		
		if params[:offset]
			offset = params[:offset] == params[:offset].to_i.to_s ? params[:offset].to_i : offset
		end
		
		weeknumbers = (0..3).map{|i| Date.today.cweek+offset+i}		
		render :partial => "overview", :locals => {:issue => @issue, :user => @user, :errors => @errors, :weeknumbers => weeknumbers}
	end
	
	def update
	
	end
	
	def delete
		if params[:id] && Weekeffort.find(params[:id]) && User.current.admin?
			Weekeffort.destroy(params[:id])
		end
		
		redirect_to :action => "index"
	end
	
	def validate_params
	
		@errors = []
	
		if !User.current.admin?
			@errors << "Nur mit Admin Rechten veränderbar"
			return
		end
	
		if params[:project_id].blank? || !@project = Project.find(params[:project_id])
			@errors << "Projekt nicht gefunden"
			return
		end
		
		if params[:issue_id].blank? || !@issue = Issue.find(params[:issue_id])
			@errors << "Issue wurde nicht gefunden"
			return
		end
		
		if @issue && !@project.issues.include?(@issue)
			@errors << "Ticket nicht Projekt zugeordnet!"
			return
		end
		
		if !params[:user_id].blank? && !(@user = User.find(params[:user_id]))
			@errors << "Benutzer nicht gefunden"
			return
		elsif params[:user_id].blank? && !(@user = @issue.assigned_to)
			@errors << "Bislang kein Benutzer zugeordnet"
			return
		end
	
	end
	
end
