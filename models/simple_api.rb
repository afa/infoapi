module SimpleApi
  require 'simple_api/rule'
  require 'simple_api/design_rule'
  require 'simple_api/hotels_rule'
  require 'simple_api/annotations_rule_methods'
  require 'simple_api/annotation_hotels_rule'
  require 'simple_api/hotels_catalog_annotation_rule'
  require 'simple_api/hotels_rating_annotation_rule'
  require 'simple_api/main_rule'
  require 'simple_api/about_rule'
  require 'simple_api/movies_rule'
  require 'simple_api/annotation_movies_rule'
  require 'simple_api/movies_catalog_annotation_rule'
  require 'simple_api/movies_rating_annotation_rule'
  require 'simple_api/rules'
  require 'simple_api/rule_defs'

  PARAM_MAP = {
    "hotels" => {
      "about" => AboutRule,
      "catalog-annotation" => HotelsCatalogAnnotationRule,
      "rating-annotation" => HotelsRatingAnnotationRule,
      "main" => MainRule
    },
    "movies" => {
      "catalog-annotation" => MoviesCatalogAnnotationRule,
      "rating-annotation" => MoviesRatingAnnotationRule,
      "about" => AboutRule,
      "main" => MainRule
    }
  }
  puts 'sa'
end
