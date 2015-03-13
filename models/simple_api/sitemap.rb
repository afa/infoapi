require 'simple_api/sitemap/object_data'
require 'simple_api/sitemap/index'
require 'simple_api/sitemap/root'
require 'simple_api/sitemap/reference'
require 'simple_api/sitemap/production'
require 'simple_api/sitemap/rule'
require 'simple_api/sitemap/sitemap_session'
require 'simple_api/sitemap/vocabula'
require 'workers'
module SimpleApi
  module Sitemap

      def preload_criteria
        Sentimeta.env = CONFIG["fapi_stage"] || :production
        sp_list = ((Sentimeta::Client.spheres rescue []) || []).map{|s| s["name"] }
        DB[:criteria].delete
        (SimpleApi::Rule.all.map(&:sphere).uniq & sp_list).each do |sphere|
          # Sentimeta.lang = :en
          # Sentimeta.sphere = sphere
          DB[:criteria].multi_insert(((Sentimeta::Client.criteria(:subcriteria => true, sphere: sphere, lang: :en) rescue []) || []).map{|h| h.has_key?('subcriteria') ? h['subcriteria'] : [h] }.flatten.map{|h| {label: h["label"], name: h["name"], sphere: sphere} })
        end
      end

    module_function :preload_criteria
  end
end
