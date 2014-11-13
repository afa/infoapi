Sequel.migration do
  change do
    alter_table(:rules) do
      add_column :name, String
    end
  end
end
