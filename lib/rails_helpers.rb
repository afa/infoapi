require 'logger'

def json_load(string, default = nil)
  begin
    JSON.load(string)
  rescue => e
    if default
      default
    else
      raise
    end
  end
end

def tr_h1_params(str, hash, sphere, lang)
  idents = {
  # 'location' => 'path',
  'location' => 'catalog',
  'stars' => 'stars',
  'price-range' => 'price_range',
  'amenity' => 'amenities',

  'criterion' => 'criteria',
  
  'genre' => 'genres',
  'actor' => 'actors',
  'country' => 'countries',
  'director' => 'directors',
  'producer' => 'producers',
  'writer' => 'writers',
  'year' => 'years'
  }

subs = {}
  subs.merge!('location' => hash['path'].strip.split(',').last) if hash.has_key?('path')
  subs.merge!('location' => hash['catalog'].strip.split(',').last) if hash.has_key?('catalog')
  subs.merge!('stars' => hash['stars']) if hash.has_key?('stars')
  subs.merge!('price-range' => hash['price_range']) if hash.has_key?('price_range')
  subs.merge!('amenity' => hash['amenities']) if hash.has_key?('amenity')

  subs.merge!('criterion' => hash['criteria']) if hash.has_key?('criteria')
  
  subs.merge!('genre' => hash['genres']) if hash.has_key?('genres')
  subs.merge!('actor' => hash['actors']) if hash.has_key?('actors')
  subs.merge!('country' => hash['countries']) if hash.has_key?('countries')
  subs.merge!('director' => hash['directors']) if hash.has_key?('directors')
  subs.merge!('producer' => hash['producers']) if hash.has_key?('producers')
  subs.merge!('writer' => hash['writers']) if hash.has_key?('writers')
  subs.merge!('year' => hash['years']) if hash.has_key?('years')

  rslt = str.dup
  str.scan(/(<%(.+?)%>)/) do |ar|
    key = ar.last.strip
    rslt.gsub!(ar.first, (SimpleApi::Sitemap::Vocabula.where(name: subs[key].to_s, kind: idents[key], sphere: sphere, lang: lang).first.try(:label) || subs[key].to_s))
  end
  rslt
end

class Enumerator #::Lazy
  def take_until
    if block_given?
      ary = []

      while true
        n = begin
              self.next
            rescue StopIteration
              return ary #.lazy
            end
        ary << n
      if (yield n) == true
        break
      end
      end
      return ary #.lazy
    else
      return self
    end
  end
end

# module Rails
#   def logger
#     @logger ||= Logger.new('./log/api.log', 'weekly')
#   end
#   module_function :logger
# end

class Object
  def try(*a, &b)
    if a.empty? && block_given?
      yield self
    else
      public_send(*a, &b) if respond_to?(a.first)
    end
  end
end

class String
  def blank?
    strip == ''
  end

  def present?
    !blank?
  end
end

class Array
  def blank?
    empty?
  end
  def empty?
    self == []
  end

  def present?
    !empty?
  end
end

    # def konstantize(camel_cased_word)
    #   names = camel_cased_word.split('::')

    #   # Trigger a builtin NameError exception including the ill-formed constant in the message.
    #   Object.const_get(camel_cased_word) if names.empty?

    #   # Remove the first blank element in case of '::ClassName' notation.
    #   names.shift if names.size > 1 && names.first.empty?

    #   names.inject(Object) do |constant, name|
    #     if constant == Object
    #       constant.const_get(name)
    #     else
    #       candidate = constant.const_get(name)
    #       next candidate if constant.const_defined?(name, false)
    #       next candidate unless Object.const_defined?(name)

    #       # Go down the ancestors to check it it's owned
    #       # directly before we reach Object or the end of ancestors.
    #       constant = constant.ancestors.inject do |const, ancestor|
    #         break const    if ancestor == Object
    #         break ancestor if ancestor.const_defined?(name, false)
    #         const
    #       end

    #       # owner is in Object, so raise
    #       constant.const_get(name, false)
    #     end
    #   end
    # end


class Fixnum
  def present?
    true
  end

  def blank?
    false
  end
end

class NilClass
  def present?
    false
  end

  def blank?
    true
  end

  def empty?
    true
  end
end

class Hash
  def present?
    !blank?
  end

  def blank?
    empty?
  end

  def symbolize_keys
    self.inject({}){|rslt, (k, v)| rslt.merge(k.to_sym => v) }
  end

  def reverse_merge(hash)
    hash.merge self
  end
end
