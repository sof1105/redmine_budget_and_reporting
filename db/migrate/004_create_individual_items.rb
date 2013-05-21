class CreateIndividualItems < ActiveRecord::Migration
  def change
    create_table :individual_items do |t|
      t.integer :project_id
      t.string :label
      t.date :spend_on
      t.float :costs
    end
  end
end
