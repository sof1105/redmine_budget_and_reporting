#encoding: utf-8

class WeekeffortController < ApplicationController

	before_filter :validate_params, :except => :overview_all

	def index
		offset = 0
		
		if params[:offset]
			offset = params[:offset] == params[:offset].to_i.to_s ? params[:offset].to_i : offset
		end
		
		weeknumbers = (0..3).map{|i| [offset+i, Date.today.cweek+offset+i]}
		@issue.assigned_to = @user
		@issue.save
		render :partial => "overview", :locals => {:issue => @issue, :user => @user, :errors => @errors, :weeknumbers => weeknumbers}
	end
	
	def overview_all
		c = UserCustomField.where(:name => "Abteilung").first.try(:id)
		if !c.nil?
			@users = User.joins(:custom_values).where(:custom_values => {:custom_field_id => c, :value => ["Mikroelektronik", "Konstruktion", "Elektronik Design", "Leistungselektronik"]})
		else
			@users = User.all
		end
		
                
		@offset = 0
		
		if params[:offset]
			@offset = params[:offset] == params[:offset].to_i.to_s ? params[:offset].to_i : @offset
		end
                
                
		
	end
	
	
	def update
		if params[:hours] && (!params[:weekoffset].blank? && params[:weekoffset] == params[:weekoffset].to_i.to_s)
			
				date = Date.commercial(Date.today.cwyear, Date.today.cweek+params[:weekoffset].to_i)
			
				w = Weekeffort.find_or_create_by_cweek_and_cyear_and_issue_id(date.cweek, date.cwyear, @issue.id)
				w.hours = params[:hours].to_f
				w.save
				render :partial => "update"
				return
		else
			render :partial => "update", :status => 400
		end
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
