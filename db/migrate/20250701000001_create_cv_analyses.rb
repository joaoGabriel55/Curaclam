class CreateCvAnalyses < ActiveRecord::Migration[8.1]
  def change
    create_table :cv_analyses do |t|
      t.string :status, null: false, default: "pending"
      t.text :extracted_text
      t.json :analysis_result
      t.text :error_message

      t.timestamps
    end

    add_index :cv_analyses, :status
  end
end