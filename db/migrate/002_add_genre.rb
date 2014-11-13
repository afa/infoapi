Sequel.migration do

  change do
    alter_table(:rules) do
      add_column :genres, String
    end
    SimpleApi::Rule.set_dataset :rules
  end

end

