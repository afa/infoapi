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
  def empty?
    self == []
  end

  def present?
    !empty?
  end
end

class NilClass
  def present?
    false
  end

  def blank?
    true
  end
end

class Hash
  def symbolize_keys
    self.inject({}){|rslt, (k, v)| rslt.merge(k.to_sym => v) }
  end

  def reverse_merge(hash)
    hash.merge self
  end
end
