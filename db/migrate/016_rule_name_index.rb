Sequel.migration do
  up do
    self[:rules].select(:id, :name, :sphere, :lang, :param).where(name: /[^a-z_\d\-_]/).or(name: nil).each do |rule|
      name = base_name = rule[:name] ? rule[:name].downcase.gsub(/[^a-z_\d\-_]/, '-') : 'noname'
      index = 1
      while self[:rules].select(:id)
        .where(name: name, sphere: rule[:sphere], lang: rule[:lang], param: rule[:param])
        .count > 0
        name = base_name + '-' + index.to_s
        index += 1
      end
      self[:rules].where(id: rule[:id]).update(name: name)
    end

    add_index :rules, [:sphere, :lang, :param, :name], unique: true
  end

  down do
    drop_index :rules, [:sphere, :lang, :param, :name]
  end
end
