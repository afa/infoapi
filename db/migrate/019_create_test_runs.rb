Sequel.migration do
  change do
    create_table :test_runs do
      primary_key :id
      String :system_version
      String :state, null: false
      String :content, text: true
      String :test_label
      Integer :test_application_id
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
