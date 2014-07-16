class CreateWeekefforts < ActiveRecord::Migration

	def change
		create_table :weekefforts do |t|
			t.integer :issue_id
			t.integer :user_id
			t.integer :cweek
			t.integer :cyear
			t.float :hours
		end
	end

end
