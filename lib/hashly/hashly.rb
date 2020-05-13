module Hashly
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

  # Evaluates the block on every key pair recursively. If any block is truthy, the method returns true, otherwise, false.
  def any?(hash, &block)
    raise 'hash is a required argument' if hash.nil?
    raise 'A block must be provided to this method to evaluate on each key pair. The evaluation occurs recursively. Block arguments: |k, v|' if block.nil?
    hash.each do |k, v|
      return true if yield(k, v)
      return true if v.is_a?(::Hash) && any?(v, &block) # recurse
    end
    false
  end

  # Sorts by key recursively - optionally include sorting of arrays
  def deep_sort(hash, include_arrays: true)
    raise "argument must be of type Hash - Actual type: #{hash.class}" unless hash.is_a?(::Hash)
    hash.each_with_object({}) do |(k, v), child_hash|
      child_hash[k] = case v
                      when ::Hash
                        deep_sort(v)
                      when ::Array
                        include_arrays ? v.sort : v
                      else
                        v
                      end
    end.sort.to_h
  end

  # Description:
  #   Merge two hashes with nested hashes recursively.
  # Returns:
  #   Hash with the merged data.
  # Parameters:
  #   boolean_or: use a boolean || operator on the base and override if they are not a Hash or Array instead of stomping with the override
  #   left_outer_join_depth: Only merge keys that already exist in the base for the first X levels specified.
  def deep_merge(base, override, boolean_or: false, left_outer_join_depth: 0)
    left_outer_join_depth -= 1 # decrement left_outer_join_depth for recursion
    if base.nil?
      return nil if left_outer_join_depth >= 0
      return override.is_a?(::Hash) ? override.dup : override
    end

    case override
    when nil
      base = base.dup if base.is_a?(::Hash) # duplicate hash to avoid modification by reference issues
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

  # Identifies what keys in the comparison hash are missing from base hash.
  # Optionally keep the values from the comparison hash, otherwise assigns the missing keys a value of :missing_key
  def deep_diff_by_key(base, comparison, keep_values: false)
    missing_keys = {}
    if comparison.is_a?(::Hash)
      compared_keys = base.is_a?(::Hash) ? comparison.keys - base.keys : comparison.keys # Determine what keys the comparison has that the base doesn't
      compared_keys.each { |k| missing_keys[k] = keep_values ? comparison[k] : :missing_key } # Save the missing keys
      comparison.each do |k, v|
        missing_keys[k] = deep_diff_by_key(base[k], v, keep_values: keep_values) if v.is_a?(::Hash) # Recurse to find more missing keys if the hash goes deeper
      end
    end
    missing_keys.reject { |_k, v| v.is_a?(::Hash) && v.empty? } # Remove any empty hashes as there were no missing keys in them
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

  # Deep diff two Hashes
  # Remove any keys in the first hash also contained in the second hash
  # If a key exists in the base, but NOT the comparison, it is kept.
  def deep_reject_by_hash(base, comparison)
    return nil if base.nil?

    case comparison
    when ::Hash
      return base unless base.is_a?(::Hash) # if base is not a hash but the comparison is, return the base
      base = base.dup
      comparison.each do |src_key, src_value|
        base[src_key] = deep_reject_by_hash(base[src_key], src_value) # recurse to the leaf
        base[src_key] = nil if base[src_key].is_a?(::Hash) && base[src_key].empty? # set leaves to nil if they are empty hashes
      end
      base.reject { |_k, v| v.nil? } # reject any leaves that were set to nil
    else # rubocop:disable Style/EmptyElse - for clarity
      nil # drop the value if we have reached a leaf in the comparison hash
    end
  end

  def reject_keys_with_nil_values(base)
    deep_reject(base) { |_k, v| v.nil? }
  end
end
