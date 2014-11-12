Sequel.migration do
  up do
    alter_table(:rules) do
      add_column :filter, String, text: true
      add_column :extended_types, String, text: true
    end
    SimpleApi::Rule.set_dataset :rules
    # refresh dataset
    SimpleApi::Rule.order(:id).all.each do |rule|
      # p rule.values, SimpleApi::Rule.from_param(rule.values[:sphere], rule.values[:param])
      r = SimpleApi::Rule.from_param(rule.values[:sphere], rule.values[:param]).new(rule.values)
      r.update_fields({ filter: %i(design path stars criteria genres).inject({}){|rslt, attr| rslt.merge(attr => rule.send(attr)) }.to_json}, [:filter]) # path.level 
      p r, r.filter
      p "presave", r.serialize.to_hash
      r.serialize.save
    end
  end
  down do
    alter_table(:rules) do
      drop_column :filter
      drop_column :extended_types
    end
  end
end
