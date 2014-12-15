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
  def symbolize_keys
    self.inject({}){|rslt, (k, v)| rslt.merge(k.to_sym => v) }
  end

  def reverse_merge(hash)
    hash.merge self
  end
end
