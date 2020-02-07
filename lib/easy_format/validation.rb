module EasyFormat
  module_function

  # Optional parameters should be an array of symbols or strings
  # rubocop:disable Security/Eval
  def validate_parameters(method, method_binding, optional_parameters = [])
    method.parameters.each do |parameter|
      parameter_name = parameter.last.to_s
      next if optional_parameters.any? { |o| o.to_s.casecmp(parameter_name) == 0 }
      parameter_value = eval(parameter_name, method_binding)
      raise "#{parameter_name} is a required parameter for #{caller[2][/`.*'/][1..-2]}!" if parameter_value.nil? || (parameter_value.respond_to?(:empty?) && parameter_value.empty?)
    end
  end
  # rubocop:enable Security/Eval
end
