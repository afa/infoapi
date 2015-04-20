class SimpleApi::Sitemap::Vocabula < Sequel::Model
  set_dataset :vocabulary

  VOCABULAS = {
    'hotels' => %w(location country admin1 city amenities criteria),
    'movies' => %w(genres countries directors actors producers writers criteria),
    'companies' => %w(top industries criteria)
  }

  def self.fresh?(sphere, lang, attribute)
    return false if where(lang: lang.to_s, sphere: sphere, kind: attribute).empty?
     ( ( where(lang: lang.to_s, sphere: sphere, kind: attribute).reverse_order(:id).first.try(:created_at) || Time.new(0)) > ( Time.now - (7*86400))).tap{|x| p x }
  end

  def self.take(sphere, lang, attribute)
    tm = Time.now
    return spec_load_criteria(sphere, lang) if attribute == 'criteria'
    return spec_load_catalog(sphere, lang) if (attribute == 'catalog' || attribute == 'location') && sphere == 'hotels'
    rslt = []
    offset = 0
    loop do
      data = Sentimeta::Client.fetch :attributes, {id: attribute, limit_values: 10000, offset_values: offset, sphere: sphere, lang: lang}
      break if !data.ok? || data['values'].blank?
      puts "#{offset}:#{data['values'].size}"
      rslt += data['values']
      offset += data['values'].size
    end
    rslt.each_slice(10000) do |bundl|
      print '.'
      multi_insert(bundl.map{|h| {name: h['name'], label: h['label'], created_at: tm, sphere: sphere, lang: lang.to_s, kind: attribute} })
    end
    puts "", "done #{attribute} #{rslt.size}"
  end

  def self.cleanup(sphere, lang, attribute)
    where(sphere: sphere, lang: lang, kind: attribute).delete
  end

  def self.spec_load_criteria(sphere, lang)
    tm = Time.now
    Sentimeta.env = CONFIG["fapi_stage"] || :production
    criteria = Sentimeta::Client.criteria(:subcriteria => true, sphere: sphere, lang: lang) rescue []
    multi_insert((criteria || []).map{|h| h.has_key?('subcriteria') ? h['subcriteria'] : [h] }.flatten.map{|h| {label: h["label"], name: h["name"], sphere: sphere, lang: lang, created_at: tm, kind: 'criteria'} })
  end

  def self.spec_load_catalog(sphere, lang)
    p 'ld cat'
    ctime = Time.now
    Sentimeta.env = CONFIG['fapi_stage']
    rslt = ['']
    crnt = rslt.dup
    4.times.each do
      crnt = crnt.map do |item|
        p item
        cat = Sentimeta::Client.catalog(sphere: 'hotels', path: item.blank? ? '' : item[:name], limit: 10000, lang: lang) rescue []
        cat.present? ? cat.map{|i| { name: [ item.blank? ? nil : item[:name], i['name'] ].compact.join(','), label: [ item.blank? ? nil : item[:label], i['label'] ].compact.join(',') } } : nil
      end
      .compact
      .flatten
      rslt += crnt
      PP.pp crnt
    end
    rslt.delete_if(&:blank?)
    rslt.each_slice(1000) do |items|
      print '.'
      multi_insert(items.map{|i| {name: i[:name], label: i[:label], sphere: sphere, lang: lang, kind: 'catalog', created_at: ctime} })
    end
    puts " done catalog: #{rslt.size}"

  end
end
