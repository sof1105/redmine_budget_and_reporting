class CreateSubtotals < ActiveRecord::Migration
  def change
    create_table :subtotals do |t|
		t.integer :project_id
		t.string :comment
		t.date :upto
    end
  end
end
