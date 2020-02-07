module EasyFormat
  module_function

  module Hash
    module_function

    def safe_value(hash, *keys)
      return nil if hash.nil? || hash[keys.first].nil?
      return hash[keys.first] if keys.length == 1 # return the value if we have reached the final key
      safe_value(hash[keys.shift], *keys) # recurse until we have reached the final key
    end

    def stringify_all_keys(hash)
      stringified_hash = {}
      hash.each do |k, v|
        stringified_hash[k.to_s] = v.is_a?(::Hash) ? stringify_all_keys(v) : v
      end
      stringified_hash
    end
  end

  # Deep merge two structures
  def deep_merge(base, override, boolean_or: false)
    if base.nil?
      return base if override.nil?
      return override.is_a?(Hash) ? override.dup : override
    end

    case override
    when nil
      base = base.dup if base.is_a?(Hash)
      base # if override doesn't exist, then simply copy base to it
    when ::Hash
      base = base.dup
      override.each do |src_key, src_value|
        base[src_key] = base[src_key] ? EasyFormat.deep_merge(base[src_key], src_value) : src_value
      end
      base
    when ::Array
      base |= override
      base
    when ::String, ::Integer, ::Time, ::TrueClass, ::FalseClass
      boolean_or ? base || override : override
    else
      throw "Implementation for deep merge of type #{override.class} is missing."
    end
  end
end
