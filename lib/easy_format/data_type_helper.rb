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

    def symbolize_all_keys(hash)
      symbolized_hash = {}
      hash.each do |k, v|
        symbolized_hash[k.to_sym] = v.is_a?(::Hash) ? symbolize_all_keys(v) : v
      end
      symbolized_hash
    end
  end

  # Deep merge two structures
  #   boolean_or: use a boolean || operator on the base and override if they are not a Hash or Array
  #   Left outer join: Only merge keys that already exist in the base
  def deep_merge(base, override, boolean_or: false, left_outer_join_depth: 0)
    left_outer_join_depth -= 1 # decrement left_outer_join_depth for recursion
    if base.nil?
      return nil if left_outer_join_depth >= 0
      return override.is_a?(Hash) ? override.dup : override
    end

    case override
    when nil
      base = base.dup if base.is_a?(Hash) # duplicate hash to avoid modification by reference issues
      base # if override doesn't exist, simply return the existing value
    when ::Hash
      base = base.dup
      override.each do |src_key, src_value|
        next if base[src_key].nil? && left_outer_join_depth >= 0 # if this is a left outer join and the key does not exist in the base, skip it
        base[src_key] = base[src_key] ? deep_merge(base[src_key], src_value, boolean_or: boolean_or, left_outer_join_depth: left_outer_join_depth) : src_value # Recurse if both are Hash
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

  # Identifies what keys in a hash don't have the keys contained in the comparison hash
  def deep_diff_by_key(base, comparison)
    return comparison if base.nil? && !comparison.nil?

    missing_values = {}
    if comparison.is_a?(::Hash)
      base = Mash.new(base)
      comparison.each do |src_key, src_value|
        base_key_processed_value = deep_diff_by_key(base[src_key], src_value)
        missing_values[src_key] = base_key_processed_value unless base_key_processed_value.nil?
      end
    end
    missing_values.empty? ? nil : missing_values
  end

  # Deep diff two structures
  # For a hash, returns keys found in both hashes where the values don't match.
  # If a key exists in the base, but NOT the comparison, it is NOT considered a difference so that it can be a one way comparison.
  # For an array, returns an array with values found in the comparison array but not in the base array.
  def deep_diff(base, comparison)
    if base.nil? # if base is nil, entire comparison object is different
      return comparison.is_a?(Hash) ? comparison.dup : comparison
    end

    case comparison
    when nil
      {}
    when ::Hash
      differing_values = {}
      base = base.dup
      comparison.each do |src_key, src_value|
        difference = deep_diff(base[src_key], src_value)
        differing_values[src_key] = difference unless difference == :no_diff
      end
      differing_values.reject { |_k, v| v.is_a?(::Hash) && v.empty? }
    when ::Array
      difference = comparison - base
      difference.empty? ? :no_diff : difference
    else
      base == comparison ? :no_diff : comparison
    end
  end

  # Reject hash keys however deep they are. Provide a block and if it evaluates to true for a given key/value pair, it will be rejected.
  def deep_reject(hash, &block)
    hash.each_with_object({}) do |(k, v), h|
      next if yield(k, v) # reject the current key/value pair by skipping it if the block given evaluates to true
      h[k] = v.is_a?(::Hash) ? deep_reject(v, &block) : v # recursively go up the hash tree or keep the value if it's not a hash.
    end
  end
end
